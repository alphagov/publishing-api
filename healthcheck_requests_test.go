package main_test

import (
	"net/http"
	"net/http/httptest"

	. "github.com/alphagov/publishing-api"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("GET /healthcheck", func() {
	var (
		testPublishingAPI *httptest.Server
	)

	BeforeEach(func() {
		testPublishingAPI = httptest.NewServer(BuildHTTPMux("", ""))
	})

	AfterEach(func() {
		testPublishingAPI.Close()
	})

	It("has a healthcheck endpoint which responds with a status of OK", func() {
		response, err := http.Get(testPublishingAPI.URL + "/healthcheck")
		Expect(err).To(BeNil())
		Expect(response.StatusCode).To(Equal(http.StatusOK))

		body, err := readResponseBody(response)
		Expect(err).To(BeNil())
		Expect(body).To(Equal(`{"status":"OK"}`))
	})
})
