package contentstore

import (
	"bytes"
	"errors"
	"io"
	"io/ioutil"
	"net/http"
	"strings"
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
func (p *ContentStoreClient) DoRequest(httpMethod, path string, data []byte) (*http.Response, error) {
	if len(p.rootURL) == 0 {
		// FIXME: remove once we have a draft content store wherever publishing-api is present.
		// return a dummy OK response if the client doesn't know which server to call
		return dummyOKResponse(), nil
	}

	url := p.rootURL + path
	var reqBody io.Reader

	if data != nil {
		reqBody = ioutil.NopCloser(bytes.NewBuffer(data))
	}

	req, err := http.NewRequest(httpMethod, url, reqBody)

	if err != nil {
		return nil, err
	}

	req.Header.Set("Accept", "application/json")
	if data != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	return p.client.Do(req)
}

// FIXME: remove once we have a draft content store wherever publishing-api is present.
func dummyOKResponse() *http.Response {
	return &http.Response{
		Status:     "200 OK",
		StatusCode: 200,
		Body:       ioutil.NopCloser(strings.NewReader("Draft content-store not configured. This is a dummy response")),
	}
}
