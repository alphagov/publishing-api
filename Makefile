.PHONY: deps test build

BINARY := publishing-api
ORG_PATH := github.com/alphagov
REPO_PATH := $(ORG_PATH)/$(BINARY)

all: test build

deps:
	gom install

vendor: deps
	rm -rf _vendor/src/$(ORG_PATH)
	mkdir -p _vendor/src/$(ORG_PATH)
	ln -s $(CURDIR) _vendor/src/$(REPO_PATH)

test: vendor
	gom test -v ./...

build: vendor
	gom build -o $(BINARY)

run: build
	./$(BINARY)

clean:
	rm -rf bin $(BINARY) _vendor
