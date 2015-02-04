package urlarbiter_test

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/alphagov/publishing-api/urlarbiter"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestURLArbiter(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "URL arbiter client")
}

var _ = Describe("URLArbiter", func() {
	It("should register a path successfully when the path is available", func() {
		testServer := buildTestServer(http.StatusOK, `{"path":"/foo/bar","publishing_app":"foo_publisher"}`)
		arbiter := urlarbiter.NewURLArbiter(testServer.URL)

		response, err := arbiter.Register("/foo/bar", "foo_publishing")
		Expect(err).To(BeNil())
		Expect(response.Path).To(Equal("/foo/bar"))
		Expect(response.PublishingApp).To(Equal("foo_publisher"))
	})

	It("responds with a conflict error if the path is already reserved", func() {
		testServer := buildTestServer(http.StatusConflict, `{
"path":"/foo/bar",
"publishing_app":"foo_publisher",
"errors":{"path":["is already reserved by the 'foo_publisher' app"]}
}`)
		arbiter := urlarbiter.NewURLArbiter(testServer.URL)

		response, err := arbiter.Register("/foo/bar", "foo_publishing")
		Expect(err).To(Equal(urlarbiter.ConflictPathAlreadyReserved))
		Expect(response.Errors).To(HaveLen(1))
		Expect(response.Errors["path"]).To(Equal([]string{"is already reserved by the 'foo_publisher' app"}))
	})

	It("responds with an unprocessable entity error on validation errors", func() {
		testServer := buildTestServer(422, `{
"path":"/foo/bar",
"publishing_app":"",
"errors":{"publishing_app":["can't be blank"]}
}`)
		arbiter := urlarbiter.NewURLArbiter(testServer.URL)
		response, err := arbiter.Register("/foo/bar", "")
		Expect(err).To(Equal(urlarbiter.UnprocessableEntity))
		Expect(response.Errors).To(HaveLen(1))
		Expect(response.Errors["publishing_app"]).To(Equal([]string{"can't be blank"}))
	})
})

func buildTestServer(status int, body string) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-type", "application/json")
		w.WriteHeader(status)
		fmt.Fprintln(w, body)
	}))
}
