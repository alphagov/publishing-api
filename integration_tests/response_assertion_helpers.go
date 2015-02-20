package integration

import (
	"net/http"

	. "github.com/onsi/gomega"
)

type HTTPTestResponse struct {
	Code int
	Body string
}

func AssertSameResponse(actualResponse *http.Response, expectedResponse *HTTPTestResponse) {
	Expect(actualResponse.StatusCode).To(Equal(expectedResponse.Code))

	if expectedResponse.Body != "" {
		body, err := ReadHTTPBody(actualResponse.Body)
		Expect(err).To(BeNil())
		Expect(body).To(MatchJSON(expectedResponse.Body))
	}
}

func AssertPathIsRegisteredAndContentStoreResponseIsReturned(actualResponse *http.Response, expectedResponse *HTTPTestResponse) {
	// Test request order
	Expect(<-TestRequestOrderTracker).To(Equal(URLArbiterRequestLabel))
	Expect(<-TestRequestOrderTracker).To(Equal(ContentStoreRequestLabel))

	AssertSameResponse(actualResponse, expectedResponse)
}
