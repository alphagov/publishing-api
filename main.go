package main

import (
	"log"
	"net/http"
	"os"

	"github.com/alext/tablecloth"
	"github.com/codegangsta/negroni"
	"github.com/gorilla/mux"
	"gopkg.in/unrolled/render.v1"

	"github.com/alphagov/plek/go"
	"github.com/alphagov/publishing-api/controllers"
	"github.com/alphagov/publishing-api/errornotifier"
	"github.com/alphagov/publishing-api/request_logger"
)

var (
	arbiterURL          = plek.Find("url-arbiter")
	liveContentStoreURL = getEnvDefault("CONTENT_STORE", "http://content-store.dev.gov.uk")
	port                = getEnvDefault("PORT", "3093")
	requestLogDest      = getEnvDefault("REQUEST_LOG", "STDOUT")

	draftContentStoreURL = os.Getenv("DRAFT_CONTENT_STORE")

	renderer = render.New(render.Options{})

	errbitHost    = os.Getenv("ERRBIT_HOST")
	errbitApiKey  = os.Getenv("ERRBIT_API_KEY")
	errbitEnvName = os.Getenv("ERRBIT_ENVIRONMENT_NAME")
	errorNotifier errornotifier.Notifier
)

func BuildHTTPMux(arbiterURL, liveContentStoreURL, draftContentStoreURL string, errorNotifier errornotifier.Notifier) http.Handler {
	httpMux := mux.NewRouter()

	httpMux.Methods("GET").Path("/healthcheck").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		renderer.JSON(w, http.StatusOK, map[string]string{"status": "OK"})
	})

	contentItemsController := controllers.NewContentItemsController(arbiterURL, liveContentStoreURL, draftContentStoreURL, errorNotifier)
	httpMux.Methods("PUT").Path("/draft-content{base_path:/.*}").HandlerFunc(contentItemsController.PutDraftContentItem)
	httpMux.Methods("PUT").Path("/content{base_path:/.*}").HandlerFunc(contentItemsController.PutLiveContentItem)

	publishIntentsController := controllers.NewPublishIntentsController(arbiterURL, liveContentStoreURL, errorNotifier)
	httpMux.Methods("PUT").Path("/publish-intent{base_path:/.*}").HandlerFunc(publishIntentsController.PutPublishIntent)
	httpMux.Methods("GET").Path("/publish-intent{base_path:/.*}").HandlerFunc(publishIntentsController.GetPublishIntent)
	httpMux.Methods("DELETE").Path("/publish-intent{base_path:/.*}").HandlerFunc(publishIntentsController.DeletePublishIntent)

	return httpMux
}

func main() {
	if errbitHost != "" && errbitApiKey != "" && errbitEnvName != "" {
		errorNotifier = errornotifier.NewErrbitNotifier(errbitHost, errbitApiKey, errbitEnvName)
	}

	httpMux := BuildHTTPMux(arbiterURL, liveContentStoreURL, draftContentStoreURL, errorNotifier)

	requestLogger, err := request_logger.New(requestLogDest)
	if err != nil {
		if errorNotifier != nil {
			errorNotifier.Notify(err, &http.Request{})
		}
		log.Fatal(err)
	}

	middleware := negroni.New()
	middleware.Use(requestLogger)
	middleware.UseHandler(httpMux)

	// Set working dir for tablecloth if available. This is to allow restarts
	// to pick up new versions.  See
	// http://godoc.org/github.com/alext/tablecloth#pkg-variables for details
	if wd := os.Getenv("GOVUK_APP_ROOT"); wd != "" {
		tablecloth.WorkingDir = wd
	}

	err = tablecloth.ListenAndServe(":"+port, middleware)
	if err != nil {
		if errorNotifier != nil {
			errorNotifier.Notify(err, &http.Request{})
		}
		log.Fatal(err)
	}
}

func getEnvDefault(key string, defaultVal string) string {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}

	return val
}
