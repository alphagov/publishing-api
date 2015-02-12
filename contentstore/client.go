package contentstore

import (
	"bytes"
	"errors"
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

func (p *ContentStoreClient) PutRequest(path string, data []byte) (*http.Response, error) {
	url := p.rootURL + path

	reqBody := ioutil.NopCloser(bytes.NewBuffer(data))
	req, err := http.NewRequest("PUT", url, reqBody)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	return p.client.Do(req)
}

func (p *ContentStoreClient) GetRequest(path string) (*http.Response, error) {
	url := p.rootURL + path

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	return p.client.Do(req)
}

func (p *ContentStoreClient) DeleteRequest(path string) (*http.Response, error) {
	url := p.rootURL + path

	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return nil, err
	}

	return p.client.Do(req)
}
