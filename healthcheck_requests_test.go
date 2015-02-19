package main_test

import (
	"net/http"
	"net/http/httptest"

	. "github.com/alphagov/publishing-api"
	. "github.com/alphagov/publishing-api/testhelpers"

	. "github.com/onsi/ginkgo"
)

var _ = Describe("GET /healthcheck", func() {
	It("has a healthcheck endpoint which responds with a status of OK", func() {
		var testPublishingAPI = httptest.NewServer(BuildHTTPMux("", ""))

		actualResponse := DoRequest("GET", testPublishingAPI.URL+"/healthcheck", nil)

		var expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: `{"status":"OK"}`}
		AssertSameResponse(actualResponse, &expectedResponse)
	})
})
