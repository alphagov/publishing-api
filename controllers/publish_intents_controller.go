package controllers

import (
	"net/http"

	"github.com/alphagov/publishing-api/contentstore"
	"github.com/alphagov/publishing-api/errornotifier"
	"github.com/alphagov/publishing-api/urlarbiter"
)

type PublishIntentsController struct {
	arbiter          *urlarbiter.URLArbiter
	liveContentStore *contentstore.ContentStoreClient
	errbitNotifier   errornotifier.Notifier
}

func NewPublishIntentsController(arbiterURL, liveContentStoreURL string, errbitNotifier errornotifier.Notifier) *PublishIntentsController {
	return &PublishIntentsController{
		arbiter:          urlarbiter.NewURLArbiter(arbiterURL),
		liveContentStore: contentstore.NewClient(liveContentStoreURL),
		errbitNotifier:   errbitNotifier,
	}
}

func (c *PublishIntentsController) PutPublishIntent(w http.ResponseWriter, r *http.Request) {
	requestBody, contentStoreRequest := readRequest(w, r, c.errbitNotifier)
	if contentStoreRequest != nil {
		if urlArbiterResponse, err := c.arbiter.Register(extractBasePath(r), contentStoreRequest.PublishingApp); err != nil {
			handleURLArbiterResponse(urlArbiterResponse, err, w, r, c.errbitNotifier)
			return
		}
		resp, err := c.liveContentStore.DoRequest("PUT", r.URL.Path, requestBody)
		handleContentStoreResponse(resp, err, w, r, c.errbitNotifier)
	}
}

func (c *PublishIntentsController) GetPublishIntent(w http.ResponseWriter, r *http.Request) {
	resp, err := c.liveContentStore.DoRequest("GET", r.URL.Path, nil)
	handleContentStoreResponse(resp, err, w, r, c.errbitNotifier)
}

func (c *PublishIntentsController) DeletePublishIntent(w http.ResponseWriter, r *http.Request) {
	resp, err := c.liveContentStore.DoRequest("DELETE", r.URL.Path, nil)
	handleContentStoreResponse(resp, err, w, r, c.errbitNotifier)
}
