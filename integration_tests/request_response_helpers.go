package integration

import (
	"bytes"
	"io"
	"io/ioutil"
	"net/http"
	"strings"

	. "github.com/onsi/gomega"
)

func readResponseBody(response *http.Response) (string, error) {
	body, err := ioutil.ReadAll(response.Body)
	defer response.Body.Close()

	return strings.TrimSpace(string(body)), err
}

func doRequest(verb string, url string, body []byte) *http.Response {
	var client = &http.Client{}

	request, err := http.NewRequest(verb, url, bytes.NewBuffer(body))
	Expect(err).To(BeNil())
	request.Header.Add("Content-Type", "application/json")

	response, err := client.Do(request)
	Expect(err).To(BeNil())
	return response
}

func readHTTPBody(HTTPBody io.ReadCloser) ([]byte, error) {
	body, err := ioutil.ReadAll(HTTPBody)
	defer HTTPBody.Close()

	return body, err
}
