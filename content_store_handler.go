package main

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"

	"github.com/alphagov/publishing-api/contentstore"
	"github.com/alphagov/publishing-api/urlarbiter"
)

type ContentStoreRequest struct {
	PublishingApp string `json:"publishing_app"`
}

type ContentStoreHandler struct {
	arbiter      *urlarbiter.URLArbiter
	contentStore *contentstore.ContentStoreClient
}

func NewContentStoreHandler(arbiterURL, contentStoreURL string) *ContentStoreHandler {
	return &ContentStoreHandler{
		arbiter:      urlarbiter.NewURLArbiter(arbiterURL),
		contentStore: contentstore.NewClient(contentStoreURL),
	}
}

func (cs *ContentStoreHandler) PutContentItem(w http.ResponseWriter, r *http.Request) {
	path := r.URL.Path[len("/content"):]

	requestBody, err := ioutil.ReadAll(r.Body)
	if err != nil {
		renderer.JSON(w, http.StatusInternalServerError, err)
		return
	}

	var contentStoreRequest *ContentStoreRequest
	if err := json.Unmarshal(requestBody, &contentStoreRequest); err != nil {
		switch err.(type) {
		case *json.SyntaxError:
			renderer.JSON(w, http.StatusBadRequest, err)
		default:
			renderer.JSON(w, http.StatusInternalServerError, err)
		}
		return
	}

	if !cs.registerWithURLArbiter(path, contentStoreRequest.PublishingApp, w) {
		// errors already written to ResponseWriter
		return
	}

	resp, err := cs.contentStore.PutContentItem(path, requestBody)
	if err != nil {
		renderer.JSON(w, http.StatusInternalServerError, err)
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

// Register the given path and publishing app with the URL arbiter.  Returns
// true on success.  On failure, writes an error to the ResponseWriter, and
// returns false
func (cs *ContentStoreHandler) registerWithURLArbiter(path, publishingApp string, w http.ResponseWriter) bool {
	urlArbiterResponse, err := cs.arbiter.Register(path, publishingApp)
	if err != nil {
		switch err {
		case urlarbiter.ConflictPathAlreadyReserved:
			renderer.JSON(w, http.StatusConflict, urlArbiterResponse)
		case urlarbiter.UnprocessableEntity:
			renderer.JSON(w, 422, urlArbiterResponse) // Unprocessable Entity.
		default:
			renderer.JSON(w, http.StatusInternalServerError, err)
		}
		return false
	}
	return true
}
