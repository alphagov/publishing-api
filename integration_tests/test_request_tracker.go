package integration

import "net/http"

type TestRequestLabel int

const (
	URLArbiterRequestLabel TestRequestLabel = iota
	ContentStoreRequestLabel
)

var TestRequestOrderTracker chan TestRequestLabel

func trackRequest(requestLabel TestRequestLabel) http.HandlerFunc {
	return func(w http.ResponseWriter, req *http.Request) {
		TestRequestOrderTracker <- requestLabel
	}
}
