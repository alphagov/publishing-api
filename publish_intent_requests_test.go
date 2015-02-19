package main_test

import (
	"net/http"
	"net/http/httptest"

	. "github.com/alphagov/publishing-api"
	. "github.com/alphagov/publishing-api/testhelpers"

	. "github.com/onsi/ginkgo"
)

var _ = Describe("Publish Intent Requests", func() {
	urlArbiterRequestExpectations := HTTPTestServerRequest{}
	contentStoreRequestExpectations := HTTPTestServerRequest{}

	urlArbiterResponseStubs := HTTPTestServerResponse{}
	contentStoreResponseStubs := HTTPTestServerResponse{}

	publishingAPIResponseToClient := HTTPTestServerResponse{}

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
			contentItemPayload = []byte(contentItemJSON)
			errorResponse      = `{"publishing_app":"foo_publisher","path":"/foo/bar","errors":{"a":["b","c"]}}`
		)

		BeforeEach(func() {
			TestRequestTracker = make(chan TestRequestLabel, 2)
		})

		Context("PUT", func() {
			Context("when URL arbiter errs", func() {
				BeforeEach(func() {
					urlArbiterResponseStubs.Body = errorResponse
					publishingAPIResponseToClient.Body = errorResponse
				})

				It("returns a 422 status with the original response", func() {
					urlArbiterResponseStubs.Code = 422

					actualResponse := DoRequest("PUT", endpoint, contentItemPayload)

					publishingAPIResponseToClient = HTTPTestServerResponse{Code: 422}
					AssertSameResponse(actualResponse, &publishingAPIResponseToClient)
				})

				It("returns a 409 status with the original response", func() {
					urlArbiterResponseStubs.Code = 409

					actualResponse := DoRequest("PUT", endpoint, contentItemPayload)

					publishingAPIResponseToClient = HTTPTestServerResponse{Code: 409}
					AssertSameResponse(actualResponse, &publishingAPIResponseToClient)
				})
			})

			Context("when URL arbiter and Content Store return OK", func() {
				BeforeEach(func() {
					urlArbiterResponseStubs.Code = http.StatusOK
					contentStoreResponseStubs.Code = http.StatusOK
					contentStoreResponseStubs.Body = contentItemJSON
				})

				It("registers a path with URL arbiter and then publishes the content to the content store", func() {
					contentStoreRequestExpectations.Path = "/publish-intent/foo/bar"
					contentStoreRequestExpectations.Method = "PUT"
					contentStoreRequestExpectations.Body = contentItemJSON

					actualResponse := DoRequest("PUT", endpoint, contentItemPayload)

					publishingAPIResponseToClient = HTTPTestServerResponse{Code: http.StatusOK, Body: contentItemJSON}
					AssertPathIsRegisteredAndContentStoreResponseIsReturned(actualResponse, &publishingAPIResponseToClient)
				})
			})

			It("returns a 400 error if given invalid JSON", func() {
				actualResponse := DoRequest("PUT", endpoint, []byte("i'm not json"))

				publishingAPIResponseToClient = HTTPTestServerResponse{Code: http.StatusBadRequest}
				AssertSameResponse(actualResponse, &publishingAPIResponseToClient)
			})
		})

		Context("GET", func() {
			It("passes back the JSON", func() {
				contentStoreRequestExpectations.Path = "/publish-intent/foo/bar"
				contentStoreRequestExpectations.Method = "GET"
				contentStoreRequestExpectations.Body = ""

				var publishIntentJSON = `{"some": "json", "representing a": "publish-intent"}`
				contentStoreResponseStubs.Code = http.StatusOK
				contentStoreResponseStubs.Body = publishIntentJSON

				actualResponse := DoRequest("GET", endpoint, nil)

				publishingAPIResponseToClient = HTTPTestServerResponse{Code: http.StatusOK, Body: publishIntentJSON}
				AssertSameResponse(actualResponse, &publishingAPIResponseToClient)
			})
		})
	})
})
