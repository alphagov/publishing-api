package main

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"

	"github.com/alext/tablecloth"
	"github.com/codegangsta/negroni"
	"gopkg.in/unrolled/render.v1"

	"github.com/alphagov/publishing-api/request_logger"
	"github.com/alphagov/publishing-api/urlarbiter"
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

func ContentStoreHandler(arbiterURL, contentStoreURL string) http.HandlerFunc {
	parsedContentStoreURL, err := url.Parse(contentStoreURL)
	if err != nil {
		panic(err)
	}

	arbiter := urlarbiter.NewURLArbiter(arbiterURL)
	contentStoreProxy := httputil.NewSingleHostReverseProxy(parsedContentStoreURL)
	contentStoreHostRewriter := requestHostToDestinationHost(contentStoreProxy)

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

		// Due to the way that Go works, we can't read from the
		// http.Request body twice. This is because http.Request.Body
		// implements io.ReadCloser which closes itself once read. To
		// get around this it's possible to copy the raw bytes from
		// the body into a buffer and overlay two separate
		// bytes.NewBuffer instances. Here we're implementing the same
		// io.ReadCloser interface on top of our bytes.NewBuffer and
		// replacing the original body with itself.
		r.Body = ioutil.NopCloser(bytes.NewBuffer(requestBody))

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

		contentStoreHostRewriter.ServeHTTP(w, r)
	}
}

func BuildHTTPMux(arbiterURL, contentStoreURL string) *http.ServeMux {
	httpMux := http.NewServeMux()
	httpMux.HandleFunc("/healthcheck", HealthCheckHandler)
	httpMux.HandleFunc("/content/", ContentStoreHandler(arbiterURL, contentStoreURL))
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

// Use this function to wrap httputil.NewSingleHostReverseProxy
// proxies. It sets the host of the request to the host of the
// destination server.
func requestHostToDestinationHost(handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		r.Host = r.URL.Host
		handler.ServeHTTP(w, r)
	})
}
