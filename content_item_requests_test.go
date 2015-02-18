package main_test

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"

	. "github.com/alphagov/publishing-api"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Content Item Requests", func() {
	var (
		testPublishingAPI *httptest.Server
	)

	BeforeEach(func() {
		testPublishingAPI = httptest.NewServer(BuildHTTPMux("", ""))
	})

	AfterEach(func() {
		testPublishingAPI.Close()
	})

	Describe("PUT /content", func() {
		var (
			requestOrder     chan TestRequestLabel
			testContentStore *httptest.Server
			testURLArbiter   *httptest.Server
		)

		BeforeEach(func() {
			requestOrder = make(chan TestRequestLabel, 2)

			testContentStore = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				requestOrder <- ContentStoreRequestLabel

				Expect(r.URL.Path).To(Equal("/content/foo/bar"))
				Expect(r.Method).To(Equal("PUT"))

				w.WriteHeader(http.StatusOK)
				fmt.Fprintln(w, `{
						"base_path": "/foo/bar",
						"title": "Content Title",
						"description": "Short description of content",
						"format": "the format of this content",
						"locale": "en",
						"details": {
						"app": "or format",
						"specific": "data..."
						}
					 }`)
			}))
			testURLArbiter = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				requestOrder <- URLArbiterRequestLabel

				defer GinkgoRecover()

				Expect(r.URL.Path).To(Equal("/paths/foo/bar"))
				Expect(r.Method).To(Equal("PUT"))

				body, err := readHTTPBody(r.Body)
				Expect(err).To(BeNil())
				Expect(body).To(MatchJSON(`{"publishing_app":"foo_publisher"}`))

				w.WriteHeader(http.StatusOK)
				fmt.Fprintln(w, `{"path":"/foo/bar","publishing_app":"foo_publisher"}`)
			}))
			testPublishingAPI = httptest.NewServer(BuildHTTPMux(testURLArbiter.URL, testContentStore.URL))
		})

		AfterEach(func() {
			testContentStore.Close()
			testURLArbiter.Close()
			testPublishingAPI.Close()
			close(requestOrder)
		})

		Context("when URL arbiter errs", func() {
			var (
				URLArbiterReturnStatus   int
				URLArbiterReturnResponse string
			)

			BeforeEach(func() {
				testURLArbiter = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
					w.WriteHeader(URLArbiterReturnStatus)
					fmt.Fprintln(w, URLArbiterReturnResponse)
				}))

				testPublishingAPI = httptest.NewServer(BuildHTTPMux(testURLArbiter.URL, testContentStore.URL))
			})

			AfterEach(func() {
				testURLArbiter.Close()
				testPublishingAPI.Close()
			})

			It("should return a 422 status with the original response", func() {
				URLArbiterReturnStatus = 422
				URLArbiterReturnResponse = `{"publishing_app":"foo_publisher","path":"/foo","errors":{"a":["b","c"]}}`

				jsonRequestBody, err := json.Marshal(&ContentStoreRequest{
					PublishingApp: "foo_publisher",
				})
				Expect(err).To(BeNil())

				url := testPublishingAPI.URL + "/content/foo/bar"

				response := doRequest("PUT", url, jsonRequestBody)
				Expect(response.StatusCode).To(Equal(422))

				body, err := readHTTPBody(response.Body)
				Expect(err).To(BeNil())
				Expect(body).To(Equal([]uint8(URLArbiterReturnResponse)))
			})

			It("should return a 409 status with the original response", func() {
				URLArbiterReturnStatus = 409
				URLArbiterReturnResponse = `{"publishing_app":"foo_publisher","path":"/foo","errors":{"a":["b"]}}`

				jsonRequestBody, err := json.Marshal(&ContentStoreRequest{
					PublishingApp: "foo_publisher",
				})
				Expect(err).To(BeNil())

				url := testPublishingAPI.URL + "/content/foo/bar"

				response := doRequest("PUT", url, jsonRequestBody)
				Expect(response.StatusCode).To(Equal(409))

				body, err := readHTTPBody(response.Body)
				Expect(err).To(BeNil())
				Expect(body).To(Equal([]uint8(URLArbiterReturnResponse)))
			})
		})

		It("registers a path with URL arbiter and then publishes the content to the content store", func() {
			jsonRequestBody, err := json.Marshal(&ContentStoreRequest{
				PublishingApp: "foo_publisher",
			})
			Expect(err).To(BeNil())

			url := testPublishingAPI.URL + "/content/foo/bar"

			response := doRequest("PUT", url, jsonRequestBody)

			Expect(response.StatusCode).To(Equal(http.StatusOK))

			// Testing for order.
			Expect(<-requestOrder).To(Equal(URLArbiterRequestLabel))
			Expect(<-requestOrder).To(Equal(ContentStoreRequestLabel))

			body, err := readHTTPBody(response.Body)
			Expect(body).To(MatchJSON(`{
					"base_path": "/foo/bar",
					"title": "Content Title",
					"description": "Short description of content",
					"format": "the format of this content",
					"locale": "en",
					"details": {
					"app": "or format",
					"specific": "data..."
					}
				}`))
			Expect(err).To(BeNil())
		})

		It("returns a 400 error if given invalid JSON", func() {
			url := testPublishingAPI.URL + "/content/foo/bar"
			response := doRequest("PUT", url, []byte("i'm not json"))
			Expect(response.StatusCode).To(Equal(http.StatusBadRequest))
		})
	})
})
