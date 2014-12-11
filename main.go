package main

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"

	"github.com/Sirupsen/logrus"
	"github.com/codegangsta/negroni"
	"github.com/meatballhat/negroni-logrus"
	"gopkg.in/unrolled/render.v1"
)

var (
	loggingMiddleware = negronilogrus.NewCustomMiddleware(
		logrus.InfoLevel, &logrus.JSONFormatter{}, "publishing-api")
	port     = getEnvDefault("PORT", "3000")
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

	arbiter := NewURLArbiter(arbiterURL)
	contentStore := httputil.NewSingleHostReverseProxy(parsedContentStoreURL)

	return func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path[len("/content"):]

		requestBody, err := ioutil.ReadAll(r.Body)
		if err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
			return
		}

		requestBodyBuffer, err := ioutil.ReadAll(bytes.NewBuffer(requestBody))
		if err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
			return
		}

		var contentStoreRequest *ContentStoreRequest
		if err := json.Unmarshal(requestBodyBuffer, &contentStoreRequest); err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
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

		_, err = arbiter.Register(path, contentStoreRequest.PublishingApp)
		if err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
			return
		}

		contentStore.ServeHTTP(w, r)
	}
}

func BuildHTTPMux(arbiterURL, contentStoreURL string) *http.ServeMux {
	httpMux := http.NewServeMux()
	httpMux.HandleFunc("/healthcheck", HealthCheckHandler)
	httpMux.HandleFunc("/content/", ContentStoreHandler(arbiterURL, contentStoreURL))
	return httpMux
}

func main() {
	// TODO: apply this using an environment variable.
	httpMux := BuildHTTPMux("dummy.arbiter.url.com", "dummy.content.store.com")

	middleware := negroni.New()
	middleware.Use(loggingMiddleware)
	middleware.UseHandler(httpMux)
	middleware.Run(":" + port)
}

func getEnvDefault(key string, defaultVal string) string {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}

	return val
}
