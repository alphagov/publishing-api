package testhelpers

import (
	"net/http"

	. "github.com/onsi/gomega"
)

func AssertSameResponse(actualResponse *http.Response, expectedResponse *HTTPTestServerResponse) {
	Expect(actualResponse.StatusCode).To(Equal(expectedResponse.Code))

	if expectedResponse.Body != "" {
		body, err := ReadHTTPBody(actualResponse.Body)
		Expect(err).To(BeNil())
		Expect(body).To(MatchJSON(expectedResponse.Body))
	}
}

func AssertPathIsRegisteredAndContentStoreResponseIsReturned(actualResponse *http.Response, expectedResponse *HTTPTestServerResponse) {
	// Test request order
	Expect(<-TestRequestTracker).To(Equal(URLArbiterRequestLabel))
	Expect(<-TestRequestTracker).To(Equal(ContentStoreRequestLabel))

	AssertSameResponse(actualResponse, expectedResponse)
}
