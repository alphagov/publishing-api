package main_test

import (
	"net/http"
	"net/http/httptest"

	. "github.com/alphagov/publishing-api"
	. "github.com/alphagov/publishing-api/testhelpers"

	. "github.com/onsi/ginkgo"
)

var _ = Describe("Publish Intent Requests", func() {
	var (
		urlArbiterRequestExpectations, contentStoreRequestExpectations       HTTPTestRequest
		urlArbiterResponseStubs, contentStoreResponseStubs, expectedResponse HTTPTestResponse
	)

	Describe("/publish-intent", func() {
		var (
			testURLArbiter   = BuildHTTPTestServer(&urlArbiterRequestExpectations, &urlArbiterResponseStubs, URLArbiterRequestLabel)
			testContentStore = BuildHTTPTestServer(&contentStoreRequestExpectations, &contentStoreResponseStubs, ContentStoreRequestLabel)

			testPublishingAPI = httptest.NewServer(BuildHTTPMux(testURLArbiter.URL, testContentStore.URL))
			endpoint          = testPublishingAPI.URL + "/publish-intent/foo/bar"

			contentItemJSON = `{
          "base_path": "/foo/bar",
          "title": "Content Title",
          "description": "Short description of content",
          "format": "the format of this content",
          "locale": "en",
          "details": {
          "app": "or format",
          "specific": "data..."
          }
        }`
			contentItemPayload      = []byte(contentItemJSON)
			urlArbiterResponse      = `{"path":"/foo/bar","publishing_app":"foo_publisher"}`
			urlArbiterErrorResponse = `{"publishing_app":"foo_publisher","path":"/foo/bar","errors":{"a":["b","c"]}}`
		)

		BeforeEach(func() {
			TestRequestTracker = make(chan TestRequestLabel, 2)
		})

		Context("PUT", func() {
			Context("when URL arbiter errs", func() {
				It("returns a 422 status with the original response", func() {
					urlArbiterResponseStubs = HTTPTestResponse{Code: 422, Body: urlArbiterErrorResponse}

					actualResponse := DoRequest("PUT", endpoint, contentItemPayload)

					expectedResponse = HTTPTestResponse{Code: 422, Body: urlArbiterErrorResponse}
					AssertSameResponse(actualResponse, &expectedResponse)
				})

				It("returns a 409 status with the original response", func() {
					urlArbiterResponseStubs = HTTPTestResponse{Code: 409, Body: urlArbiterErrorResponse}

					actualResponse := DoRequest("PUT", endpoint, contentItemPayload)

					expectedResponse = HTTPTestResponse{Code: 409, Body: urlArbiterErrorResponse}
					AssertSameResponse(actualResponse, &expectedResponse)
				})
			})

			It("registers a path with URL arbiter and then publishes the content to the content store", func() {
				urlArbiterResponseStubs = HTTPTestResponse{Code: http.StatusOK, Body: urlArbiterResponse}
				contentStoreResponseStubs = HTTPTestResponse{Code: http.StatusOK, Body: contentItemJSON}
				contentStoreRequestExpectations = HTTPTestRequest{Path: "/publish-intent/vat-rates", Method: "PUT", Body: contentItemJSON}

				actualResponse := DoRequest("PUT", endpoint, contentItemPayload)

				expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: contentItemJSON}
				AssertPathIsRegisteredAndContentStoreResponseIsReturned(actualResponse, &expectedResponse)
			})

			It("returns a 400 error if given invalid JSON", func() {
				actualResponse := DoRequest("PUT", endpoint, []byte("i'm not json"))

				expectedResponse = HTTPTestResponse{Code: http.StatusBadRequest}
				AssertSameResponse(actualResponse, &expectedResponse)
			})
		})

		Context("GET", func() {
			It("passes back the JSON", func() {
				contentStoreRequestExpectations = HTTPTestRequest{Path: "/publish-intent/foo/bar", Method: "GET", Body: ""}

				var publishIntentJSON = `{"some": "json", "representing a": "publish-intent"}`
				contentStoreResponseStubs = HTTPTestResponse{Code: http.StatusOK, Body: publishIntentJSON}

				actualResponse := DoRequest("GET", endpoint, nil)

				expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: publishIntentJSON}
				AssertSameResponse(actualResponse, &expectedResponse)
			})
		})
	})
})
