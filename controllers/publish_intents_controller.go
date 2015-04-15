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
		liveContentStore: contentstore.NewClient(liveContentStoreURL, false),
	}
}

func (c *PublishIntentsController) PutPublishIntent(w http.ResponseWriter, r *http.Request) {
	requestBody, contentStoreRequest := readRequest(w, r)
	if contentStoreRequest != nil {
		if urlArbiterResponse, err := c.arbiter.Register(extractBasePath(r), contentStoreRequest.PublishingApp); err != nil {
			handleURLArbiterResponse(urlArbiterResponse, err, w)
			return
		}
		doContentStoreRequest(c.liveContentStore, "PUT", r.URL.Path, requestBody, w)
	}
}

func (c *PublishIntentsController) GetPublishIntent(w http.ResponseWriter, r *http.Request) {
	doContentStoreRequest(c.liveContentStore, "GET", r.URL.Path, nil, w)
}

func (c *PublishIntentsController) DeletePublishIntent(w http.ResponseWriter, r *http.Request) {
	doContentStoreRequest(c.liveContentStore, "DELETE", r.URL.Path, nil, w)
}
