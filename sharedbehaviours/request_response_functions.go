package sharedbehaviours

import (
	"bytes"
	"io"
	"io/ioutil"
	"net/http"
	"strings"

	. "github.com/onsi/gomega"
)

func ReadResponseBody(response *http.Response) (string, error) {
	body, err := ioutil.ReadAll(response.Body)
	defer response.Body.Close()

	return strings.TrimSpace(string(body)), err
}

func DoRequest(verb string, url string, body []byte) *http.Response {
	var client = &http.Client{}

	request, err := http.NewRequest(verb, url, bytes.NewBuffer(body))
	Expect(err).To(BeNil())

	response, err := client.Do(request)
	Expect(err).To(BeNil())
	return response
}

func ReadHTTPBody(HTTPBody io.ReadCloser) ([]byte, error) {
	body, err := ioutil.ReadAll(HTTPBody)
	defer HTTPBody.Close()

	return body, err
}
