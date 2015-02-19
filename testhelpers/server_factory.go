package testhelpers

import (
	"fmt"
	"net/http"
	"net/http/httptest"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

type HTTPTestServerResponse struct {
	Code int
	Body string
}

type HTTPTestServerRequest struct {
	Path   string
	Method string
	Body   string
}

func BuildHTTPTestServer(request *HTTPTestServerRequest, response *HTTPTestServerResponse, requestLabel TestRequestLabel) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer GinkgoRecover()

		TestRequestTracker <- requestLabel

		if request.Path != "" {
			Expect(r.URL.Path).To(Equal(request.Path))
		}
		if request.Method != "" {
			Expect(r.Method).To(Equal(request.Method))
		}

		body, err := ReadHTTPBody(r.Body)
		Expect(err).To(BeNil())
		if request.Body != "" {
			Expect(body).To(MatchJSON(request.Body))
		}

		w.WriteHeader(response.Code)
		fmt.Fprintln(w, response.Body)
	}))
}
