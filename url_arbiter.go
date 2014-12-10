package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"io/ioutil"
	"net/http"
)

var ConflictPathAlreadyReserved = errors.New("path is already reserved")

type URLArbiter struct {
	client  *http.Client
	rootURL string
}

type URLArbiterResponse struct {
	publishingApp

	Path   string              `json:"path"`
	Errors map[string][]string `json:"errors"`
}

type publishingApp struct {
	PublishingApp string `json:"publishing_app"`
}

func NewURLArbiter(rootURL string) *URLArbiter {
	return &URLArbiter{
		client:  &http.Client{},
		rootURL: rootURL,
	}
}

func (u *URLArbiter) Register(path, publishingAppName string) (URLArbiterResponse, error) {
	url := u.rootURL + "/paths" + path
	requestBody := publishingApp{PublishingApp: publishingAppName}
	jsonRequestBody, _ := json.Marshal(requestBody)

	request, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonRequestBody))
	if err != nil {
		return URLArbiterResponse{}, err
	}

	response, err := u.client.Do(request)
	if err != nil {
		return URLArbiterResponse{}, err
	}

	responseBody, err := readResponseBody(response)
	if err != nil {
		return URLArbiterResponse{}, err
	}

	var arbiterResponse URLArbiterResponse
	if err := json.Unmarshal(responseBody, &arbiterResponse); err != nil {
		return URLArbiterResponse{}, err
	}

	// Read the response body and then check the status code so we can
	// return the errors from the response.
	if response.StatusCode == http.StatusConflict {
		return arbiterResponse, ConflictPathAlreadyReserved
	}

	return arbiterResponse, nil
}

func readResponseBody(response *http.Response) ([]byte, error) {
	body, err := ioutil.ReadAll(response.Body)
	defer response.Body.Close()

	return body, err
}
