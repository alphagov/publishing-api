.PHONY: all test build run clean check_fmt

BINARY := publishing-api
SOURCE_FILES := $(shell find . -type f -name '*.go')
ORG_PATH := github.com/alphagov
IMPORT_PATH := $(ORG_PATH)/publishing-api
VENDOR_STAMP := _vendor/stamp

all: check_fmt test build

deps: $(VENDOR_STAMP)

test: $(VENDOR_STAMP)
	gom test -v ./...

build: $(BINARY)

run: $(BINARY)
	./$(BINARY)

clean:
	rm -rf $(BINARY) _vendor

check_fmt:
	./check_fmt.sh

$(BINARY): $(VENDOR_STAMP) $(SOURCE_FILES)
	gom build -o $(BINARY)

$(VENDOR_STAMP): Gomfile
	rm -rf _vendor/src/$(IMPORT_PATH)
	mkdir -p _vendor/src/$(ORG_PATH)
	ln -s ../../../.. _vendor/src/$(IMPORT_PATH)
	gom install
	touch $(VENDOR_STAMP)
