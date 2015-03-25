package contentstore_test

import (
	"io/ioutil"
	"net/http"
	"testing"

	"github.com/alphagov/publishing-api/contentstore"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/ghttp"
)

func TestURLArbiter(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "URL arbiter client")
}

var _ = Describe("URLArbiter", func() {
	var (
		testServer *ghttp.Server
	)

	BeforeEach(func() {
		testServer = ghttp.NewServer()
	})

	AfterEach(func() {
		testServer.Close()
	})

	Describe("DoRequest with a body", func() {
		It("should send the body on the path with the HTTP method to content-store", func() {
			responseBody := `{"base_path":"/foo/bar","remaining_fields":"omitted"}`
			testServer.AppendHandlers(
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("PUT", "/foo/bar"),
					ghttp.VerifyContentType("application/json"),
					ghttp.VerifyHeaderKV("Accept", "application/json"),
					verifyRequestBody("Something"),
					ghttp.RespondWith(http.StatusOK, responseBody, http.Header{"Content-Type": []string{"application/json"}}),
				),
			)

			client := contentstore.NewClient(testServer.URL())

			response, err := client.DoRequest("PUT", "/foo/bar", []byte("Something"))

			Expect(testServer.ReceivedRequests()).To(HaveLen(1))

			Expect(err).To(BeNil())
			Expect(response.StatusCode).To(Equal(http.StatusOK))
		})
	})

	Describe("DoRequest without a body", func() {
		It("should send a request to the path with the HTTP method to content-store", func() {
			responseBody := `{"base_path":"/foo/bar","remaining_fields":"omitted"}`
			testServer.AppendHandlers(
				ghttp.CombineHandlers(
					ghttp.VerifyRequest("GET", "/foo/bar"),
					ghttp.RespondWith(http.StatusOK, responseBody, http.Header{"Content-Type": []string{"application/json"}}),
				),
			)

			client := contentstore.NewClient(testServer.URL())

			response, err := client.DoRequest("GET", "/foo/bar", nil)

			Expect(testServer.ReceivedRequests()).To(HaveLen(1))

			Expect(err).To(BeNil())
			Expect(response.StatusCode).To(Equal(http.StatusOK))
		})
	})
})

func verifyRequestBody(expectedBody string) http.HandlerFunc {
	return func(w http.ResponseWriter, req *http.Request) {
		body, err := ioutil.ReadAll(req.Body)
		req.Body.Close()
		Expect(err).NotTo(HaveOccurred())
		Expect(string(body)).To(Equal(expectedBody))
	}
}
