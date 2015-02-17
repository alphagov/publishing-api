package contentstore

import (
	"bytes"
	"errors"
	"io"
	"io/ioutil"
	"net/http"
)

var (
	UnprocessableEntity = errors.New("request was well-formed but was unable to be followed due to semantic errors")
)

type ContentStoreClient struct {
	client  *http.Client
	rootURL string
}

func NewClient(rootURL string) *ContentStoreClient {
	return &ContentStoreClient{
		client:  &http.Client{},
		rootURL: rootURL,
	}
}

// data will be nil for requests without bodies
func (p *ContentStoreClient) DoRequest(httpMethod string, path string, data []byte) (*http.Response, error) {
	url := p.rootURL + path
	var reqBody io.Reader

	if data != nil {
		reqBody = ioutil.NopCloser(bytes.NewBuffer(data))
	}

	req, err := http.NewRequest(httpMethod, url, reqBody)

	if err != nil {
		return nil, err
	}

	if data != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	return p.client.Do(req)
}
