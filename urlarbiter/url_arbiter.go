package urlarbiter

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
)

var (
	UnexpectedResponse          = errors.New("unexpected response")
	ConflictPathAlreadyReserved = errors.New("path is already reserved")
	UnprocessableEntity         = errors.New("request was well-formed but was unable to be followed due to semantic errors")
)

type URLArbiter struct {
	client  *http.Client
	rootURL string
}

type URLArbiterResponse struct {
	PublishingApplication

	Path   string              `json:"path"`
	Errors map[string][]string `json:"errors"`
}

type PublishingApplication struct {
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
	requestBody := PublishingApplication{PublishingApp: publishingAppName}
	jsonRequestBody, _ := json.Marshal(requestBody)

	request, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonRequestBody))
	request.Header.Set("Content-Type", "application/json")

	if err != nil {
		return URLArbiterResponse{}, err
	}

	response, err := u.client.Do(request)
	if err != nil {
		return URLArbiterResponse{}, err
	}

	var arbiterResponse URLArbiterResponse
	if err := json.NewDecoder(response.Body).Decode(&arbiterResponse); err != nil {
		return URLArbiterResponse{}, err
	}

	if response.StatusCode >= 200 && response.StatusCode < 300 {
		return arbiterResponse, nil
	} else {
		switch response.StatusCode {
		case 422: // Unprocessable Entity.
			return arbiterResponse, UnprocessableEntity
		case http.StatusConflict:
			return arbiterResponse, ConflictPathAlreadyReserved
		default:
			return arbiterResponse, UnexpectedResponse
		}
	}
}
