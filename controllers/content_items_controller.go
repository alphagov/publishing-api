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
	requestBody, contentStoreRequest := readRequest(w, r)
	if contentStoreRequest != nil {
		if !registerWithURLArbiter(c.arbiter, extractBasePath(r), contentStoreRequest.PublishingApp, w) {
			return
		}
		doContentStoreRequest(c.draftContentStore, "PUT", strings.Replace(r.URL.Path, "/draft-content/", "/content/", 1), requestBody, w)
	}
}

func (c *ContentItemsController) PutLiveContentItem(w http.ResponseWriter, r *http.Request) {
	requestBody, contentStoreRequest := readRequest(w, r)
	if contentStoreRequest != nil {
		if !registerWithURLArbiter(c.arbiter, extractBasePath(r), contentStoreRequest.PublishingApp, w) {
			return
		}

		var wg sync.WaitGroup
		wg.Add(2)
		go func() {
			defer wg.Done()
			doContentStoreRequest(c.liveContentStore, "PUT", r.URL.Path, requestBody, w)
		}()
		go func() {
			defer wg.Done()
			// for now, we ignore the response from draft content store for storing live content, hence `w` is nil
			doContentStoreRequest(c.draftContentStore, "PUT", r.URL.Path, requestBody, nil)
		}()
		wg.Wait()
	}
}
