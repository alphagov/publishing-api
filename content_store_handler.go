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
	BasePath      string `json:"base_path"`
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

func (cs *ContentStoreHandler) PutContentStoreRequest(w http.ResponseWriter, r *http.Request) {
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

	if !cs.registerWithURLArbiter(contentStoreRequest.BasePath, contentStoreRequest.PublishingApp, w) {
		// errors already written to ResponseWriter
		return
	}

	resp, err := cs.contentStore.PutRequest(r.URL.Path, requestBody)
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

func (cs *ContentStoreHandler) GetContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	resp, err := cs.contentStore.GetRequest(r.URL.Path)
	if err != nil {
		renderer.JSON(w, http.StatusInternalServerError, err)
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func (cs *ContentStoreHandler) DeleteContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	resp, err := cs.contentStore.DeleteRequest(r.URL.Path)
	if err != nil {
		renderer.JSON(w, http.StatusInternalServerError, err)
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}
