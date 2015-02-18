package sharedbehaviours

import (
	"encoding/json"

	. "github.com/alphagov/publishing-api"
	. "github.com/onsi/gomega"
)

type TestContext struct {
	Endpoint string
}

type URLArbiterResponse struct {
	Code int
	Body string
}

func AssertURLArbiterResponseIsReturned(testContext *TestContext, urlArbiterResponse *URLArbiterResponse) {
	jsonRequestBody, err := json.Marshal(&ContentStoreRequest{
		PublishingApp: "foo_publisher",
	})
	Expect(err).To(BeNil())

	response := DoRequest("PUT", testContext.Endpoint, jsonRequestBody)
	Expect(response.StatusCode).To(Equal(urlArbiterResponse.Code))

	body, err := ReadHTTPBody(response.Body)
	Expect(err).To(BeNil())
	Expect(body).To(Equal([]uint8(urlArbiterResponse.Body)))
}
