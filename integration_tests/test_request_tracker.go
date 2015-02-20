package integration

type TestRequestLabel int

const (
	URLArbiterRequestLabel TestRequestLabel = iota
	ContentStoreRequestLabel
)

var TestRequestTracker chan TestRequestLabel
