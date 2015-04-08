package controllers

import (
	"net/http"
	"strings"
	"sync"

	"github.com/alphagov/publishing-api/contentstore"
	"github.com/alphagov/publishing-api/urlarbiter"
)

type ContentItemsController struct {
	arbiter           *urlarbiter.URLArbiter
	liveContentStore  *contentstore.ContentStoreClient
	draftContentStore *contentstore.ContentStoreClient
}

func NewContentItemsController(arbiterURL, liveContentStoreURL, draftContentStoreURL string) *ContentItemsController {
	return &ContentItemsController{
		arbiter:           urlarbiter.NewURLArbiter(arbiterURL),
		liveContentStore:  contentstore.NewClient(liveContentStoreURL, false),
		draftContentStore: contentstore.NewClient(draftContentStoreURL, true),
	}
}

func (c *ContentItemsController) PutDraftContentItem(w http.ResponseWriter, r *http.Request) {
	registerWithURLArbiterAndForward(c.arbiter, w, r, func(basePath string, requestBody []byte) {
		doContentStoreRequest(c.draftContentStore, "PUT", strings.Replace(basePath, "/draft-content/", "/content/", 1), requestBody, w)
	})
}

func (c *ContentItemsController) PutLiveContentItem(w http.ResponseWriter, r *http.Request) {
	registerWithURLArbiterAndForward(c.arbiter, w, r, func(basePath string, requestBody []byte) {
		var wg sync.WaitGroup
		wg.Add(2)
		go func() {
			defer wg.Done()
			doContentStoreRequest(c.liveContentStore, "PUT", basePath, requestBody, w)
		}()
		go func() {
			defer wg.Done()
			// for now, we ignore the response from draft content store for storing live content, hence `w` is nil
			doContentStoreRequest(c.draftContentStore, "PUT", basePath, requestBody, nil)
		}()
		wg.Wait()
	})
}
