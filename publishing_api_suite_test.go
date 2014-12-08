package main_test

import (
	"io/ioutil"
	"net/http"
	"strings"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestPublishingApi(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "PublishingApi Suite")
}

func readResponseBody(response *http.Response) (string, error) {
	body, err := ioutil.ReadAll(response.Body)
	defer response.Body.Close()

	return strings.TrimSpace(string(body)), err
}
