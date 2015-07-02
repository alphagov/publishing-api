package integration

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"

	"github.com/alphagov/publishing-api"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/ghttp"
)

var _ = Describe("Content Item Requests", func() {
	contentItemWithAccessLimiting := map[string]interface{}{
		"base_path":      "/vat-rates",
		"title":          "VAT Rates",
		"description":    "VAT rates for goods and services",
		"format":         "guide",
		"publishing_app": "mainstream_publisher",
		"locale":         "en",
		"details": map[string]interface{}{
			"app":      "or format",
			"specific": "data...",
		},
		"access_limited": map[string]interface{}{
			"users": []string{
				"f17250b0-7540-0131-f036-005056030202",
				"74c7d700-5b4a-0131-7a8e-005056030037",
			},
		},
	}

	contentItem := make(map[string]interface{})

	for k, v := range contentItemWithAccessLimiting {
		if k != "access_limited" {
			contentItem[k] = v
		}
	}

	var testPublishingAPI *httptest.Server
	var testURLArbiter, testDraftContentStore, testLiveContentStore *ghttp.Server
	var endpoint string

	var expectedResponse HTTPTestResponse

	// Mock server configurations. A default is set in the BeforeEach, but can be
	// overridden if needed in your test.
	var urlArbiterResponseCode int
	var urlArbiterResponseBody string

	BeforeEach(func() {
		// URL arbiter mock server - default response (override in your test if needed)
		urlArbiterResponseCode = http.StatusOK
		urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher"}`

		TestRequestOrderTracker = make(chan TestRequestLabel, 3)

		testURLArbiter = ghttp.NewServer()
		testDraftContentStore = ghttp.NewServer()
		testLiveContentStore = ghttp.NewServer()

		testURLArbiter.AppendHandlers(ghttp.CombineHandlers(
			trackRequest(URLArbiterRequestLabel),
			ghttp.VerifyRequest("PUT", "/paths/vat-rates"),
			ghttp.VerifyJSON(`{"publishing_app": "mainstream_publisher"}`),
			ghttp.RespondWithPtr(&urlArbiterResponseCode, &urlArbiterResponseBody, http.Header{"Content-Type": []string{"application/json"}}),
		))

		testPublishingAPI = httptest.NewServer(main.BuildHTTPMux(testURLArbiter.URL(), testLiveContentStore.URL(), testDraftContentStore.URL(), nil))
		endpoint = testPublishingAPI.URL + "/content/vat-rates"
	})

	AfterEach(func() {
		testURLArbiter.Close()
		testDraftContentStore.Close()
		testLiveContentStore.Close()
		testPublishingAPI.Close()
		close(TestRequestOrderTracker)
	})

	Describe("PUT /content", func() {
		Context("when URL arbiter errs", func() {
			It("returns a 422 status with the original response", func() {
				urlArbiterResponseCode = 422
				urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is not valid"]}}`

				actualResponse := doJSONRequest("PUT", endpoint, contentItem)

				Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
				Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
				Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

				expectedResponse = HTTPTestResponse{Code: 422, Body: urlArbiterResponseBody}
				assertSameResponse(actualResponse, &expectedResponse)
			})

			It("returns a 409 status with the original response", func() {
				urlArbiterResponseCode = 409
				urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is already taken"]}}`

				actualResponse := doJSONRequest("PUT", endpoint, contentItem)

				Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
				Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
				Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

				expectedResponse = HTTPTestResponse{Code: 409, Body: urlArbiterResponseBody}
				assertSameResponse(actualResponse, &expectedResponse)
			})
		})

		It("registers a path with URL arbiter and then publishes the content to the live and draft content store", func() {
			testDraftContentStore.AppendHandlers(ghttp.CombineHandlers(
				trackRequest(DraftContentStoreRequestLabel),
				ghttp.VerifyRequest("PUT", "/content/vat-rates"),
				ghttp.VerifyJSONRepresenting(contentItem),
				ghttp.RespondWithJSONEncoded(http.StatusOK, contentItem),
			))

			testLiveContentStore.AppendHandlers(ghttp.CombineHandlers(
				trackRequest(LiveContentStoreRequestLabel),
				ghttp.VerifyRequest("PUT", "/content/vat-rates"),
				ghttp.VerifyJSONRepresenting(contentItem),
				ghttp.RespondWithJSONEncoded(http.StatusOK, contentItem),
			))

			actualResponse := doJSONRequest("PUT", endpoint, contentItem)

			Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
			Expect(testDraftContentStore.ReceivedRequests()).To(HaveLen(1))
			Expect(testLiveContentStore.ReceivedRequests()).To(HaveLen(1))

			expectedBody, _ := json.Marshal(contentItem)
			expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: string(expectedBody[:])}
			assertSameResponse(actualResponse, &expectedResponse)

			// assert that url-arbiter is called before making requests to content stores. communication
			// with live and draft content stores happens in parallel, so can't assert on their order.
			Expect(<-TestRequestOrderTracker).To(Equal(URLArbiterRequestLabel))
			Expect(<-TestRequestOrderTracker > URLArbiterRequestLabel).To(BeTrue())
			Expect(<-TestRequestOrderTracker > URLArbiterRequestLabel).To(BeTrue())
		})

		It("returns a 400 error if given invalid JSON", func() {
			actualResponse := doRequest("PUT", endpoint, []byte("i'm not json"))

			Expect(testURLArbiter.ReceivedRequests()).To(BeZero())
			Expect(testDraftContentStore.ReceivedRequests()).To(BeZero())
			Expect(testLiveContentStore.ReceivedRequests()).To(BeZero())

			expectedResponseBody := `{"message": "Invalid JSON in request body: invalid character 'i' looking for beginning of value"}`
			expectedResponse = HTTPTestResponse{Code: http.StatusBadRequest, Body: expectedResponseBody}
			assertSameResponse(actualResponse, &expectedResponse)
		})

		It("returns Content-Type header as received from content-store", func() {
			testDraftContentStore.AppendHandlers(
				ghttp.RespondWithJSONEncoded(http.StatusOK, contentItem),
			)
			testLiveContentStore.AppendHandlers(
				ghttp.RespondWithJSONEncoded(http.StatusOK, contentItem, http.Header{"Content-Type": []string{"text/html"}}),
			)

			actualResponse := doJSONRequest("PUT", endpoint, contentItem)

			Expect(testLiveContentStore.ReceivedRequests()).To(HaveLen(1))
			Expect(actualResponse.Header.Get("Content-Type")).To(Equal("text/html"))
		})

		It("strips access limiting metadata from the document", func() {
			testDraftContentStore.AppendHandlers(ghttp.CombineHandlers(
				ghttp.VerifyJSONRepresenting(contentItem),
				ghttp.RespondWithJSONEncoded(http.StatusOK, contentItem),
			))

			testLiveContentStore.AppendHandlers(ghttp.CombineHandlers(
				ghttp.VerifyJSONRepresenting(contentItem),
				ghttp.RespondWithJSONEncoded(http.StatusOK, contentItem),
			))

			actualResponse := doJSONRequest("PUT", endpoint, contentItemWithAccessLimiting)

			Expect(testDraftContentStore.ReceivedRequests()).To(HaveLen(1))
			Expect(testLiveContentStore.ReceivedRequests()).To(HaveLen(1))

			expectedBody, _ := json.Marshal(contentItem)
			expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: string(expectedBody[:])}
			assertSameResponse(actualResponse, &expectedResponse)
		})

		Context("with SUPPRESS_DRAFT_STORE_502_ERROR set to 1", func() {
			It("returns the live content-store response when the draft content store is not running", func() {
				os.Setenv("SUPPRESS_DRAFT_STORE_502_ERROR", "1")
				defer os.Unsetenv("SUPPRESS_DRAFT_STORE_502_ERROR")

				semaphore := make(chan struct{})

				testDraftContentStore.AppendHandlers(
					http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
						w.WriteHeader(http.StatusBadGateway)

						// Set semaphore to ensure draft request wins the race.
						semaphore <- struct{}{}
					}),
				)

				testLiveContentStore.AppendHandlers(ghttp.CombineHandlers(
					ghttp.VerifyJSONRepresenting(contentItem),
					http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
						// Block on semaphore being sent by draft handler
						<-semaphore

						w.Header().Set("Content-Type", "application/json")
						w.WriteHeader(http.StatusCreated)
						w.Write([]byte("{}\n"))
					}),
				))

				actualResponse := doJSONRequest("PUT", endpoint, contentItem)

				expectedResponse = HTTPTestResponse{Code: http.StatusCreated, Body: "{}\n"}
				assertSameResponse(actualResponse, &expectedResponse)
			})
		})
	})
})
