package integration

import (
	"net/http"
	"net/http/httptest"

	"github.com/alphagov/publishing-api"

	. "github.com/onsi/ginkgo"
)

var _ = Describe("GET /healthcheck", func() {
	It("has a healthcheck endpoint which responds with a status of OK", func() {
		var testPublishingAPI = httptest.NewServer(main.BuildHTTPMux("", "", "", nil))

		actualResponse := doRequest("GET", testPublishingAPI.URL+"/healthcheck", nil)

		var expectedResponse = HTTPTestResponse{Code: http.StatusOK, Body: `{"status":"OK"}`}
		assertSameResponse(actualResponse, &expectedResponse)
	})
})
