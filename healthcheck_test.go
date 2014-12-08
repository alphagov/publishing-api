package main_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Healthcheck", func() {
	It("passes", func() {
		Expect(1).To(Equal(1))
	})
})
