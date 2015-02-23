package integration

import (
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

func TestPublishingApi(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "PublishingApi Suite")
}
