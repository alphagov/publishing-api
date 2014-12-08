package main

import (
	"net/http"
	"os"

	"github.com/codegangsta/negroni"
	"gopkg.in/unrolled/render.v1"
)

var (
	renderer = render.New(render.Options{})
)

func HealthCheckHandler(w http.ResponseWriter, r *http.Request) {
	renderer.JSON(w, http.StatusOK, map[string]string{"status": "OK"})
}

func main() {
	httpMux := http.NewServeMux()
	httpMux.HandleFunc("/healthcheck", HealthCheckHandler)

	middleware := negroni.New()
	middleware.UseHandler(httpMux)
	middleware.Run(":3000")
}
