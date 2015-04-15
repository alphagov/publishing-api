package controllers

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"

	"github.com/alphagov/publishing-api/errornotifier"
	"github.com/alphagov/publishing-api/urlarbiter"
	"github.com/gorilla/mux"
	"gopkg.in/unrolled/render.v1"
)

var renderer = render.New(render.Options{})

type ContentStoreRequest struct {
	PublishingApp string `json:"publishing_app"`
}

type ErrorResponse struct {
	Message string `json:"message"`
}

func NewErrorResponse(message string, err error) *ErrorResponse {
	return &ErrorResponse{
		Message: message + ": " + err.Error(),
	}
}

func handleURLArbiterResponse(urlArbiterResponse urlarbiter.URLArbiterResponse, err error,
	w http.ResponseWriter, r *http.Request, errbitNotifier errornotifier.Notifier) {

	if err != nil {
		switch err {
		case urlarbiter.ConflictPathAlreadyReserved:
			renderer.JSON(w, http.StatusConflict, urlArbiterResponse)
		case urlarbiter.UnprocessableEntity:
			renderer.JSON(w, 422, urlArbiterResponse)
		default:
			message := "Unexpected error whilst registering with url-arbiter"
			renderer.JSON(w, http.StatusInternalServerError, NewErrorResponse(message, err))
		}
	}
}

func handleContentStoreResponse(resp *http.Response, err error, w http.ResponseWriter,
	r *http.Request, errbitNotifier errornotifier.Notifier) {

	if resp != nil {
		defer resp.Body.Close()
	}

	if w != nil {
		if err != nil {
			renderer.JSON(w, http.StatusInternalServerError, NewErrorResponse("Unexpected error in request to content-store", err))
			return
		}

		w.Header().Set("Content-Type", resp.Header.Get("Content-Type"))
		w.WriteHeader(resp.StatusCode)
		io.Copy(w, resp.Body)
	}
}

func extractBasePath(r *http.Request) string {
	urlParameters := mux.Vars(r)
	return urlParameters["base_path"]
}

func readRequest(w http.ResponseWriter, r *http.Request, errbitNotifier errornotifier.Notifier) ([]byte, *ContentStoreRequest) {
	requestBody, err := ioutil.ReadAll(r.Body)
	if err != nil {
		renderer.JSON(w, http.StatusInternalServerError, NewErrorResponse("Unexpected error in reading your request body", err))
		return nil, nil
	}

	var contentStoreRequest *ContentStoreRequest
	if err := json.Unmarshal(requestBody, &contentStoreRequest); err != nil {
		switch err.(type) {
		case *json.SyntaxError:
			renderer.JSON(w, http.StatusBadRequest, NewErrorResponse("Invalid JSON in request body", err))
		default:
			renderer.JSON(w, http.StatusInternalServerError, NewErrorResponse("Unexpected error unmarshalling your request body to JSON", err))
		}
		return nil, nil
	}

	return requestBody, contentStoreRequest
}
