package main_test

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

type TestRequestLabel int

const (
	URLArbiterRequestLabel TestRequestLabel = iota
	ContentStoreRequestLabel
)

func TestPublishingApi(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "PublishingApi Suite")
}
