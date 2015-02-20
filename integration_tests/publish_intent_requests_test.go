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

		testPublishingAPI                *httptest.Server
		testURLArbiter, testContentStore *ghttp.Server

		urlArbiterResponseCode, contentStoreResponseCode           int
		urlArbiterResponseBody, contentStoreResponseBody, endpoint string

		expectedResponse HTTPTestResponse
	)

	BeforeEach(func() {
		TestRequestOrderTracker = make(chan TestRequestLabel, 2)

		testURLArbiter = ghttp.NewServer()
		testContentStore = ghttp.NewServer()

		testPublishingAPI = httptest.NewServer(main.BuildHTTPMux(testURLArbiter.URL(), testContentStore.URL()))
		endpoint = testPublishingAPI.URL + "/publish-intent/vat-rates"
	})

	AfterEach(func() {
		testURLArbiter.Close()
		testContentStore.Close()
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

				testContentStore.AppendHandlers(
					ghttp.CombineHandlers(
						trackRequest(ContentStoreRequestLabel),
						ghttp.VerifyRequest("PUT", "/publish-intent/vat-rates"),
						ghttp.VerifyJSON(publishIntentJSON),
						ghttp.RespondWithPtr(&contentStoreResponseCode, &contentStoreResponseBody),
					),
				)
			})

			Context("when URL arbiter errs", func() {
				It("returns a 422 status with the original response", func() {
					urlArbiterResponseCode = 422
					urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is not valid"]}}`

					actualResponse := doRequest("PUT", endpoint, publishIntentPayload)

					Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
					Expect(testContentStore.ReceivedRequests()).To(BeEmpty())

					expectedResponse = HTTPTestResponse{Code: 422, Body: urlArbiterResponseBody}
					assertSameResponse(actualResponse, &expectedResponse)
				})

				It("returns a 409 status with the original response", func() {
					urlArbiterResponseCode = 409
					urlArbiterResponseBody = `{"path":"/vat-rates","publishing_app":"mainstream_publisher","errors":{"base_path":["is already taken"]}}`

					actualResponse := doRequest("PUT", endpoint, publishIntentPayload)

					Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
					Expect(testContentStore.ReceivedRequests()).To(BeEmpty())

					expectedResponse = HTTPTestResponse{Code: 409, Body: urlArbiterResponseBody}
					assertSameResponse(actualResponse, &expectedResponse)
				})
			})

			It("registers a path with URL arbiter and then forwards the publish intent to the content store", func() {
				urlArbiterResponseCode, urlArbiterResponseBody = http.StatusOK, urlArbiterResponse
				contentStoreResponseCode, contentStoreResponseBody = http.StatusOK, publishIntentJSON

				actualResponse := doRequest("PUT", endpoint, publishIntentPayload)

				Expect(testURLArbiter.ReceivedRequests()).To(HaveLen(1))
				Expect(testContentStore.ReceivedRequests()).To(HaveLen(1))

				expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: publishIntentJSON}
				assertPathIsRegisteredAndContentStoreResponseIsReturned(actualResponse, &expectedResponse)
			})

			It("returns a 400 error if given invalid JSON", func() {
				actualResponse := doRequest("PUT", endpoint, []byte("i'm not json"))

				Expect(testURLArbiter.ReceivedRequests()).To(BeEmpty())
				Expect(testURLArbiter.ReceivedRequests()).To(BeEmpty())

				expectedResponse = HTTPTestResponse{Code: http.StatusBadRequest}
				assertSameResponse(actualResponse, &expectedResponse)
			})
		})

		Context("GET", func() {
			BeforeEach(func() {
				testContentStore.AppendHandlers(
					ghttp.CombineHandlers(
						trackRequest(ContentStoreRequestLabel),
						ghttp.VerifyRequest("GET", "/publish-intent/vat-rates"),
						ghttp.RespondWithPtr(&contentStoreResponseCode, &contentStoreResponseBody),
					),
				)
			})

			It("passes back the JSON", func() {
				contentStoreResponseCode, contentStoreResponseBody = http.StatusOK, publishIntentJSON

				actualResponse := doRequest("GET", endpoint, nil)

				Expect(testURLArbiter.ReceivedRequests()).To(BeEmpty())
				Expect(testContentStore.ReceivedRequests()).To(HaveLen(1))

				expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: publishIntentJSON}
				assertSameResponse(actualResponse, &expectedResponse)
			})
		})
	})
})
