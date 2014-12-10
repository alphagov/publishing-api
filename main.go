package main

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
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

func ContentStoreHandler(arbiterURL string) http.HandlerFunc {
	arbiter := NewURLArbiter(arbiterURL)

	return func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path[len("/content"):]

		requestBody, err := ReadRequestBody(r)
		if err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
			return
		}

		var contentStoreRequest *ContentStoreRequest
		if err := json.Unmarshal(requestBody, &contentStoreRequest); err != nil {
			renderer.JSON(w, http.StatusInternalServerError, err)
			return
		}

		arbiter.Register(path, contentStoreRequest.PublishingApp)
	}
}

func BuildHTTPMux(arbiterURL string) *http.ServeMux {
	httpMux := http.NewServeMux()
	httpMux.HandleFunc("/healthcheck", HealthCheckHandler)
	httpMux.HandleFunc("/content/", ContentStoreHandler(arbiterURL))
	return httpMux
}

func main() {
	// TODO: apply this using an environment variable.
	httpMux := BuildHTTPMux("dummy.arbiter.url.com")

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

func ReadRequestBody(request *http.Request) ([]byte, error) {
	body, err := ioutil.ReadAll(request.Body)
	defer request.Body.Close()

	return body, err
}
