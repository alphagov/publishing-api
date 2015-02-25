package controllers

import (
	"net/http"

	"github.com/alphagov/publishing-api/contentstore"
	"github.com/alphagov/publishing-api/urlarbiter"
)

type PublishIntentsController struct {
	arbiter          *urlarbiter.URLArbiter
	liveContentStore *contentstore.ContentStoreClient
}

func NewPublishIntentsController(arbiterURL, liveContentStoreURL string) *PublishIntentsController {
	return &PublishIntentsController{
		arbiter:          urlarbiter.NewURLArbiter(arbiterURL),
		liveContentStore: contentstore.NewClient(liveContentStoreURL),
	}
}

func (c *PublishIntentsController) PutPublishIntent(w http.ResponseWriter, r *http.Request) {
	registerWithURLArbiterAndForward(c.arbiter, w, r, func(basePath string, requestBody []byte) {
		doContentStoreRequest(c.liveContentStore, "PUT", basePath, requestBody, w)
	})
}

func (c *PublishIntentsController) GetPublishIntent(w http.ResponseWriter, r *http.Request) {
	doContentStoreRequest(c.liveContentStore, "GET", r.URL.Path, nil, w)
}

func (c *PublishIntentsController) DeletePublishIntent(w http.ResponseWriter, r *http.Request) {
	doContentStoreRequest(c.liveContentStore, "DELETE", r.URL.Path, nil, w)
}
