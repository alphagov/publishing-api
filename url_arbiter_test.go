package main_test

import (
	"fmt"
	"net/http"
	"net/http/httptest"

	. "github.com/alphagov/publishing-api"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("URLArbiter", func() {
	It("should register a path successfully when the path is available", func() {
		testServer := buildTestServer(http.StatusOK, `{"path":"/foo/bar","publishing_app":"foo_publisher"}`)
		arbiter := NewURLArbiter(testServer.URL)

		response, err := arbiter.Register("/foo/bar", "foo_publishing")
		Expect(err).To(BeNil())
		Expect(response.Path).To(Equal("/foo/bar"))
		Expect(response.PublishingApp).To(Equal("foo_publisher"))
	})
})

func buildTestServer(status int, body string) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(status)
		fmt.Fprintln(w, body)
	}))
}
