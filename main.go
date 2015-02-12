package main

import (
	"log"
	"net/http"
	"os"

	"github.com/alext/tablecloth"
	"github.com/codegangsta/negroni"
	"github.com/gorilla/mux"
	"gopkg.in/unrolled/render.v1"

	"github.com/alphagov/publishing-api/request_logger"
)

var (
	arbiterHost      = getEnvDefault("URL_ARBITER", "http://url-arbiter.dev.gov.uk")
	contentStoreHost = getEnvDefault("CONTENT_STORE", "http://content-store.dev.gov.uk")
	port             = getEnvDefault("PORT", "3000")
	requestLogDest   = getEnvDefault("REQUEST_LOG", "STDOUT")

	renderer = render.New(render.Options{})
)

func HealthCheckHandler(w http.ResponseWriter, r *http.Request) {
	renderer.JSON(w, http.StatusOK, map[string]string{"status": "OK"})
}

func BuildHTTPMux(arbiterURL, contentStoreURL string) http.Handler {
	httpMux := mux.NewRouter()
	httpMux.Methods("GET").Path("/healthcheck").HandlerFunc(HealthCheckHandler)
	contentStoreHandler := NewContentStoreHandler(arbiterURL, contentStoreURL)
	httpMux.Methods("PUT").PathPrefix("/content/").HandlerFunc(contentStoreHandler.PutContentStoreRequest)
	return httpMux
}

func main() {
	httpMux := BuildHTTPMux(arbiterHost, contentStoreHost)

	requestLogger, err := request_logger.New(requestLogDest)
	if err != nil {
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
