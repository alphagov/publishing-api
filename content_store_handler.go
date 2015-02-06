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
	UpdateType    string `json:"update_type"`
}

func ContentStoreHandler(arbiterURL, contentStoreURL string) http.HandlerFunc {
	arbiter := urlarbiter.NewURLArbiter(arbiterURL)
	contentStore := contentstore.NewClient(contentStoreURL)

	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "PUT" {
			responseBody := `{"errors":{"method": "only PUT HTTP methods are allowed"}}`
			renderer.JSON(w, http.StatusMethodNotAllowed, responseBody)
			return
		}

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

		urlArbiterResponse, err := arbiter.Register(path, contentStoreRequest.PublishingApp)
		if err != nil {
			switch err {
			case urlarbiter.ConflictPathAlreadyReserved:
				renderer.JSON(w, http.StatusConflict, urlArbiterResponse)
			case urlarbiter.UnprocessableEntity:
				renderer.JSON(w, 422, urlArbiterResponse) // Unprocessable Entity.
			default:
				renderer.JSON(w, http.StatusInternalServerError, err)
			}

			return
		}

		resp, err := contentStore.PutContentItem(path, requestBody)
		if err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
		}
		defer resp.Body.Close()

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(resp.StatusCode)
		io.Copy(w, resp.Body)
	}
}
