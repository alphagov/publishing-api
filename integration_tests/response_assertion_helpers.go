package integration

import (
	"net/http"

	. "github.com/onsi/gomega"
)

type HTTPTestResponse struct {
	Code int
	Body string
}

func assertSameResponse(actualResponse *http.Response, expectedResponse *HTTPTestResponse) {
	Expect(actualResponse.StatusCode).To(Equal(expectedResponse.Code))

	if expectedResponse.Body != "" {
		body, err := readHTTPBody(actualResponse.Body)
		Expect(err).To(BeNil())
		Expect(body).To(MatchJSON(expectedResponse.Body))
	}
}

func assertRequestOrder(requestLabels ...TestRequestLabel) {
	for _, requestLabel := range requestLabels {
		Expect(<-TestRequestOrderTracker).To(Equal(requestLabel))
	}
}
