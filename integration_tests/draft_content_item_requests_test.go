package integration

import (
	"net/http"
	"net/http/httptest"

	"github.com/alphagov/publishing-api"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/ghttp"
)

var _ = Describe("Draft Content Item Requests", func() {
	var (
		contentItemJSON = `{
      "base_path": "/vat-rates",
      "title": "Draft VAT Rates",
      "description": "VAT rates for goods and services",
      "format": "guide",
      "publishing_app": "mainstream_publisher",
      "locale": "en",
      "details": {
        "app": "or format",
        "specific": "data..."
      }
    }`
		contentItemPayload = []byte(contentItemJSON)
		urlArbiterResponse = `{"path":"/vat-rates","publishing_app":"mainstream_publisher"}`

		testPublishingAPI                                           *httptest.Server
		testURLArbiter, testLiveContentStore, testDraftContentStore *ghttp.Server

		urlArbiterResponseCode, liveContentStoreResponseCode, draftContentStoreResponseCode           int
		urlArbiterResponseBody, liveContentStoreResponseBody, draftContentStoreResponseBody, endpoint string

		expectedResponse HTTPTestResponse
	)

	BeforeEach(func() {
		TestRequestOrderTracker = make(chan TestRequestLabel, 3)

		testURLArbiter = ghttp.NewServer()
		testURLArbiter.AppendHandlers(ghttp.CombineHandlers(
			trackRequest(URLArbiterRequestLabel),
			ghttp.VerifyRequest("PUT", "/paths/vat-rates"),
			ghttp.VerifyJSON(`{"publishing_app": "mainstream_publisher"}`),
			ghttp.RespondWithPtr(&urlArbiterResponseCode, &urlArbiterResponseBody),
		))

		testDraftContentStore = ghttp.NewServer()
		testDraftContentStore.AppendHandlers(ghttp.CombineHandlers(
			trackRequest(DraftContentStoreRequestLabel),
			ghttp.VerifyRequest("PUT", "/content/vat-rates"),
			ghttp.VerifyJSON(contentItemJSON),
			ghttp.RespondWithPtr(&draftContentStoreResponseCode, &draftContentStoreResponseBody),
		))

		testLiveContentStore = ghttp.NewServer()
		testLiveContentStore.AppendHandlers(ghttp.CombineHandlers(
			trackRequest(LiveContentStoreRequestLabel),
			ghttp.VerifyRequest("PUT", "/content/vat-rates"),
			ghttp.VerifyJSON(contentItemJSON),
			ghttp.RespondWithPtr(&liveContentStoreResponseCode, &liveContentStoreResponseBody),
		))

		testPublishingAPI = httptest.NewServer(main.BuildHTTPMux(testURLArbiter.URL(), testLiveContentStore.URL(), testDraftContentStore.URL()))
		endpoint = testPublishingAPI.URL + "/draft-content/vat-rates"
	})

	AfterEach(func() {
		testURLArbiter.Close()
		testDraftContentStore.Close()
		testLiveContentStore.Close()
		testPublishingAPI.Close()
		close(TestRequestOrderTracker)
	})

	Describe("PUT /draft-content", func() {
		Context("when URL arbiter errs", func() {
			It("returns a 422 status with the original response and doesn't store content", func() {
				urlArbiterResponseCode = 422
				urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is not valid"]}}`

				actualResponse := doRequest("PUT", endpoint, contentItemPayload)

				Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
				Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
				Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

				expectedResponse = HTTPTestResponse{Code: 422, Body: urlArbiterResponseBody}
				assertSameResponse(actualResponse, &expectedResponse)
			})

			It("returns a 409 status with the original response and doesn't store content", func() {
				urlArbiterResponseCode = 409
				urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is already taken"]}}`

				actualResponse := doRequest("PUT", endpoint, contentItemPayload)

				Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
				Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
				Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

				expectedResponse = HTTPTestResponse{Code: 409, Body: urlArbiterResponseBody}
				assertSameResponse(actualResponse, &expectedResponse)
			})
		})

		PIt("registers a path with URL arbiter and then publishes the content only to the draft content store", func() {
			urlArbiterResponseCode, urlArbiterResponseBody = http.StatusOK, urlArbiterResponse
			draftContentStoreResponseCode, draftContentStoreResponseBody = http.StatusOK, contentItemJSON

			actualResponse := doRequest("PUT", endpoint, contentItemPayload)

			Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
			Expect(testDraftContentStore.ReceivedRequests()).To(HaveLen(1))
			Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

			expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: contentItemJSON}
			assertSameResponse(actualResponse, &expectedResponse)
			assertRequestOrder(URLArbiterRequestLabel, DraftContentStoreRequestLabel)
		})

		PIt("returns a 400 error if given invalid JSON", func() {
			actualResponse := doRequest("PUT", endpoint, []byte("i'm not json"))

			Expect(testURLArbiter.ReceivedRequests()).To(BeZero())
			Expect(testDraftContentStore.ReceivedRequests()).To(BeZero())
			Expect(testLiveContentStore.ReceivedRequests()).To(BeZero())

			expectedResponse = HTTPTestResponse{Code: http.StatusBadRequest}
			assertSameResponse(actualResponse, &expectedResponse)
		})
	})
})
