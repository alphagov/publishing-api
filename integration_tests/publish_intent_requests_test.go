package integration

import (
	"net/http"
	"net/http/httptest"
	"time"

	"github.com/alphagov/publishing-api"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/ghttp"
)

var _ = Describe("Publish Intent Requests", func() {
	var (
		threeHoursFromNow = time.Now().Add(time.Duration(3 * time.Hour)) // always in future
		publishIntentJSON = `{
		  "publish_time": "` + threeHoursFromNow.Format(time.RFC3339) + `",
		  "publishing_app": "mainstream_publisher",
		  "rendering_app": "frontend",
		  "routes": [
		    {"path": "/vat-rates", "type": "exact"}
		  ]
		}`
		publishIntentPayload = []byte(publishIntentJSON)
		urlArbiterResponse   = `{"path":"/vat-rates","publishing_app":"mainstream_publisher"}`

		testPublishingAPI                                           *httptest.Server
		testURLArbiter, testLiveContentStore, testDraftContentStore *ghttp.Server

		urlArbiterResponseCode, draftContentStoreResponseCode, liveContentStoreResponseCode           int
		urlArbiterResponseBody, draftContentStoreResponseBody, liveContentStoreResponseBody, endpoint string

		expectedResponse HTTPTestResponse
	)

	BeforeEach(func() {
		TestRequestOrderTracker = make(chan TestRequestLabel, 2)

		testURLArbiter = ghttp.NewServer()
		testLiveContentStore = ghttp.NewServer()
		testDraftContentStore = ghttp.NewServer()

		testPublishingAPI = httptest.NewServer(main.BuildHTTPMux(testURLArbiter.URL(), testLiveContentStore.URL(), testDraftContentStore.URL()))
		endpoint = testPublishingAPI.URL + "/publish-intent/vat-rates"
	})

	AfterEach(func() {
		testURLArbiter.Close()
		testDraftContentStore.Close()
		testLiveContentStore.Close()
		testPublishingAPI.Close()
		close(TestRequestOrderTracker)
	})

	Describe("/publish-intent", func() {
		Context("PUT", func() {
			BeforeEach(func() {
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
					ghttp.VerifyJSON(publishIntentJSON),
					ghttp.RespondWithPtr(&draftContentStoreResponseCode, &draftContentStoreResponseBody),
				))

				testLiveContentStore.AppendHandlers(
					ghttp.CombineHandlers(
						trackRequest(LiveContentStoreRequestLabel),
						ghttp.VerifyRequest("PUT", "/publish-intent/vat-rates"),
						ghttp.VerifyJSON(publishIntentJSON),
						ghttp.RespondWithPtr(&liveContentStoreResponseCode, &liveContentStoreResponseBody),
					),
				)
			})

			Context("when URL arbiter errs", func() {
				It("returns a 422 status with the original response", func() {
					urlArbiterResponseCode = 422
					urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is not valid"]}}`

					actualResponse := doRequest("PUT", endpoint, publishIntentPayload)

					Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
					Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
					Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

					expectedResponse = HTTPTestResponse{Code: 422, Body: urlArbiterResponseBody}
					assertSameResponse(actualResponse, &expectedResponse)
				})

				It("returns a 409 status with the original response", func() {
					urlArbiterResponseCode = 409
					urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is already taken"]}}`

					actualResponse := doRequest("PUT", endpoint, publishIntentPayload)

					Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
					Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
					Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

					expectedResponse = HTTPTestResponse{Code: 409, Body: urlArbiterResponseBody}
					assertSameResponse(actualResponse, &expectedResponse)
				})
			})

			It("registers a path with URL arbiter and then forwards the publish intent to the content store", func() {
				urlArbiterResponseCode, urlArbiterResponseBody = http.StatusOK, urlArbiterResponse
				liveContentStoreResponseCode, liveContentStoreResponseBody = http.StatusOK, publishIntentJSON

				actualResponse := doRequest("PUT", endpoint, publishIntentPayload)

				Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
				Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
				Expect(testLiveContentStore.ReceivedRequests()).To(HaveLen(1))

				expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: publishIntentJSON}
				assertSameResponse(actualResponse, &expectedResponse)
				assertRequestOrder(URLArbiterRequestLabel, LiveContentStoreRequestLabel)
			})

			It("returns a 400 error if given invalid JSON", func() {
				actualResponse := doRequest("PUT", endpoint, []byte("i'm not json"))

				Expect(testURLArbiter.ReceivedRequests()).To(BeEmpty())
				Expect(testDraftContentStore.ReceivedRequests()).To(BeEmpty())
				Expect(testLiveContentStore.ReceivedRequests()).To(BeEmpty())

				expectedResponse = HTTPTestResponse{Code: http.StatusBadRequest}
				assertSameResponse(actualResponse, &expectedResponse)
			})
		})

		Context("GET", func() {
			BeforeEach(func() {
				testLiveContentStore.AppendHandlers(
					ghttp.CombineHandlers(
						trackRequest(LiveContentStoreRequestLabel),
						ghttp.VerifyRequest("GET", "/publish-intent/vat-rates"),
						ghttp.RespondWithPtr(&liveContentStoreResponseCode, &liveContentStoreResponseBody),
					),
				)
			})

			It("passes back the JSON", func() {
				liveContentStoreResponseCode, liveContentStoreResponseBody = http.StatusOK, publishIntentJSON

				actualResponse := doRequest("GET", endpoint, nil)

				Expect(testURLArbiter.ReceivedRequests()).To(BeEmpty())
				Expect(testLiveContentStore.ReceivedRequests()).To(HaveLen(1))

				expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: publishIntentJSON}
				assertSameResponse(actualResponse, &expectedResponse)
			})
		})
	})
})
