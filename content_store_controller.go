package main

import (
	"encoding/json"
	"io"
	"io/ioutil"
	"net/http"

	"github.com/gorilla/mux"

	"github.com/alphagov/publishing-api/contentstore"
	"github.com/alphagov/publishing-api/urlarbiter"
)

type ContentStoreController struct {
	arbiter           *urlarbiter.URLArbiter
	liveContentStore  *contentstore.ContentStoreClient
	draftContentStore *contentstore.ContentStoreClient
}

type ContentStoreRequest struct {
	PublishingApp string `json:"publishing_app"`
}

func NewContentStoreController(arbiterURL, liveContentStoreURL, draftContentStoreURL string) *ContentStoreController {
	return &ContentStoreController{
		arbiter:           urlarbiter.NewURLArbiter(arbiterURL),
		liveContentStore:  contentstore.NewClient(liveContentStoreURL),
		draftContentStore: contentstore.NewClient(draftContentStoreURL),
	}
}

func (controller *ContentStoreController) PutDraftContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	urlParameters := mux.Vars(r)

	if requestBody, contentStoreRequest := controller.readRequest(w, r); contentStoreRequest != nil {
		if !controller.registerWithURLArbiter(urlParameters["base_path"], contentStoreRequest.PublishingApp, w) {
			return
		}
		controller.doDraftContentStoreRequest("PUT", "/content"+urlParameters["base_path"], requestBody, w)
	}
}

func (controller *ContentStoreController) PutContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	urlParameters := mux.Vars(r)

	if requestBody, contentStoreRequest := controller.readRequest(w, r); contentStoreRequest != nil {
		if !controller.registerWithURLArbiter(urlParameters["base_path"], contentStoreRequest.PublishingApp, w) {
			return
		}
		// TODO: PUT to both content stores concurrently
		// for now, we ignore the response from draft content store for storing live content, hence `w` is nil
		controller.doContentStoreRequest("PUT", r.URL.Path, requestBody, w)
		controller.doDraftContentStoreRequest("PUT", r.URL.Path, requestBody, nil)
	}
}

func (controller *ContentStoreController) PutPublishIntentRequest(w http.ResponseWriter, r *http.Request) {
	urlParameters := mux.Vars(r)

	if requestBody, contentStoreRequest := controller.readRequest(w, r); contentStoreRequest != nil {
		if !controller.registerWithURLArbiter(urlParameters["base_path"], contentStoreRequest.PublishingApp, w) {
			return
		}
		controller.doContentStoreRequest("PUT", r.URL.Path, requestBody, w)
	}
}

func (controller *ContentStoreController) GetContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	controller.doContentStoreRequest("GET", r.URL.Path, nil, w)
}

func (controller *ContentStoreController) DeleteContentStoreRequest(w http.ResponseWriter, r *http.Request) {
	controller.doContentStoreRequest("DELETE", r.URL.Path, nil, w)
}

// Register the given path and publishing app with the URL arbiter.  Returns
// true on success.  On failure, writes an error to the ResponseWriter, and
// returns false
func (controller *ContentStoreController) registerWithURLArbiter(path, publishingApp string, w http.ResponseWriter) bool {
	urlArbiterResponse, err := controller.arbiter.Register(path, publishingApp)
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

// data will be nil for requests without bodies
func (controller *ContentStoreController) doContentStoreRequest(httpMethod string, path string, data []byte, w http.ResponseWriter) {
	resp, err := controller.liveContentStore.DoRequest(httpMethod, path, data)
	defer resp.Body.Close()

	if err != nil {
		renderer.JSON(w, http.StatusInternalServerError, err)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func (controller *ContentStoreController) doDraftContentStoreRequest(httpMethod string, path string, data []byte, w http.ResponseWriter) {
	resp, err := controller.draftContentStore.DoRequest(httpMethod, path, data)
	defer resp.Body.Close()

	if w != nil {
		if err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(resp.StatusCode)
		io.Copy(w, resp.Body)
	}
}

func (controller *ContentStoreController) readRequest(w http.ResponseWriter, r *http.Request) ([]byte, *ContentStoreRequest) {
	requestBody, err := ioutil.ReadAll(r.Body)
	if err != nil {
		renderer.JSON(w, http.StatusInternalServerError, err)
		return nil, nil
	}

	var contentStoreRequest *ContentStoreRequest
	if err := json.Unmarshal(requestBody, &contentStoreRequest); err != nil {
		switch err.(type) {
		case *json.SyntaxError:
			renderer.JSON(w, http.StatusBadRequest, err)
		default:
			renderer.JSON(w, http.StatusInternalServerError, err)
		}
		return nil, nil
	}

	return requestBody, contentStoreRequest
}
