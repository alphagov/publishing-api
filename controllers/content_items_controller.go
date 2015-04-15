package controllers

import (
	"net/http"
	"os"
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
		liveContentStore:  contentstore.NewClient(liveContentStoreURL),
		draftContentStore: contentstore.NewClient(draftContentStoreURL),
	}
}

func (c *ContentItemsController) PutDraftContentItem(w http.ResponseWriter, r *http.Request) {
	requestBody, contentStoreRequest := readRequest(w, r)
	if contentStoreRequest != nil {
		if urlArbiterResponse, err := c.arbiter.Register(extractBasePath(r), contentStoreRequest.PublishingApp); err != nil {
			handleURLArbiterResponse(urlArbiterResponse, err, w)
			return
		}
		resp, err := c.draftContentStore.DoRequest("PUT", strings.Replace(r.URL.Path, "/draft-content/", "/content/", 1), requestBody)
		if resp.StatusCode == http.StatusBadGateway && os.Getenv("SUPPRESS_DRAFT_STORE_502_ERROR") == "1" {
			w.WriteHeader(http.StatusOK)
		} else {
			handleContentStoreResponse(resp, err, w)
		}
	}
}

func (c *ContentItemsController) PutLiveContentItem(w http.ResponseWriter, r *http.Request) {
	requestBody, contentStoreRequest := readRequest(w, r)
	if contentStoreRequest != nil {
		if urlArbiterResponse, err := c.arbiter.Register(extractBasePath(r), contentStoreRequest.PublishingApp); err != nil {
			handleURLArbiterResponse(urlArbiterResponse, err, w)
			return
		}

		var wg sync.WaitGroup
		wg.Add(2)
		go func() {
			defer wg.Done()
			resp, err := c.liveContentStore.DoRequest("PUT", r.URL.Path, requestBody)
			handleContentStoreResponse(resp, err, w)
		}()
		go func() {
			defer wg.Done()
			resp, err := c.draftContentStore.DoRequest("PUT", r.URL.Path, requestBody)
			if resp.StatusCode == http.StatusBadGateway && os.Getenv("SUPPRESS_DRAFT_STORE_502_ERROR") == "1" {
				w.WriteHeader(http.StatusOK)
			} else {
				// for now, we ignore the response from draft content store for storing live content, hence `w` is nil
				handleContentStoreResponse(resp, err, nil)
			}
		}()
		wg.Wait()
	}
}
