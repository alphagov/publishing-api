package main_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"

	. "github.com/alphagov/publishing-api"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Integration Testing", func() {
	It("registers a path with URL arbiter", func() {
		client := &http.Client{}
		jsonRequestBody, err := json.Marshal(&ContentStoreRequest{
			BasePath:      "/foo/bar",
			PublishingApp: "foo_publisher",
			UpdateType:    "publish",
		})
		Expect(err).To(BeNil())

		testURLArbiter := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer GinkgoRecover()

			Expect(r.URL.Path).To(Equal("/paths/foo/bar"))
			Expect(r.Method).To(Equal("PUT"))

			body, err := ReadRequestBody(r)
			Expect(err).To(BeNil())
			Expect(body).To(MatchJSON(`{"publishing_app":"foo_publisher"}`))

			w.WriteHeader(http.StatusOK)
			fmt.Fprintln(w, `{"path":"/foo/bar","publishing_app":"foo_publisher"}`)
		}))
		testPublishingAPI := httptest.NewServer(BuildHTTPMux(testURLArbiter.URL))

		defer testURLArbiter.Close()
		defer testPublishingAPI.Close()

		url := testPublishingAPI.URL + "/content" + "/foo/bar"

		request, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonRequestBody))
		Expect(err).To(BeNil())

		response, err := client.Do(request)
		Expect(err).To(BeNil())
		Expect(response.StatusCode).To(Equal(http.StatusOK))
	})
})
