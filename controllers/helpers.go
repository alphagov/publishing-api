package controllers

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"

	"github.com/alphagov/publishing-api/contentstore"
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

func registerWithURLArbiterAndForward(urlArbiter *urlarbiter.URLArbiter, w http.ResponseWriter, r *http.Request,
	afterRegister func(basePath string, requestBody []byte)) {

	urlParameters := mux.Vars(r)
	if requestBody, contentStoreRequest := readRequest(w, r); contentStoreRequest != nil {
		if !registerWithURLArbiter(urlArbiter, urlParameters["base_path"], contentStoreRequest.PublishingApp, w) {
			return
		}
		afterRegister(r.URL.Path, requestBody)
	}
}

// Register the given path and publishing app with the URL arbiter.  Returns
// true on success.  On failure, writes an error to the ResponseWriter, and
// returns false
func registerWithURLArbiter(urlArbiter *urlarbiter.URLArbiter, path, publishingApp string, w http.ResponseWriter) bool {
	urlArbiterResponse, err := urlArbiter.Register(path, publishingApp)
	if err != nil {
		switch err {
		case urlarbiter.ConflictPathAlreadyReserved:
			renderer.JSON(w, http.StatusConflict, urlArbiterResponse)
		case urlarbiter.UnprocessableEntity:
			renderer.JSON(w, 422, urlArbiterResponse)
		default:
			renderer.JSON(w, http.StatusInternalServerError, err)
		}
		return false
	}
	return true
}

// data will be nil for requests without bodies
func doContentStoreRequest(contentStoreClient *contentstore.ContentStoreClient,
	httpMethod string, path string, data []byte, w http.ResponseWriter) {

	resp, err := contentStoreClient.DoRequest(httpMethod, path, data)
	if resp != nil {
		defer resp.Body.Close()
	}

	if w != nil {
		if err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(resp.StatusCode)
		io.Copy(w, resp.Body)
	}
}

func readRequest(w http.ResponseWriter, r *http.Request) ([]byte, *ContentStoreRequest) {
	requestBody, err := ioutil.ReadAll(r.Body)
	if err != nil {
		renderer.JSON(w, http.StatusInternalServerError, err)
		return nil, nil
	}

	var contentStoreRequest *ContentStoreRequest
	if err := json.Unmarshal(requestBody, &contentStoreRequest); err != nil {
		switch err.(type) {
		case *json.SyntaxError:
			renderer.JSON(w, http.StatusBadRequest, ErrorResponse{Message: "Invalid JSON in request body"})
		default:
			renderer.JSON(w, http.StatusInternalServerError, err)
		}
		return nil, nil
	}

	return requestBody, contentStoreRequest
}
