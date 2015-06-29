.PHONY: all test build run clean check_fmt

BINARY := publishing-api
ORG_PATH := github.com/alphagov
IMPORT_PATH := $(ORG_PATH)/publishing-api
VENDOR_STAMP := _vendor/stamp

all: check_fmt test build

deps: $(VENDOR_STAMP)

test: $(VENDOR_STAMP)
	gom test -v ./...

build: $(VENDOR_STAMP)
	gom build -o $(BINARY)

run: build
	./$(BINARY)

clean:
	rm -rf bin $(BINARY) _vendor

check_fmt:
	./check_fmt.sh

$(VENDOR_STAMP): Gomfile
	rm -rf _vendor/src/$(IMPORT_PATH)
	mkdir -p _vendor/src/$(ORG_PATH)
	ln -s ../../../.. _vendor/src/$(IMPORT_PATH)
	gom install
	touch $(VENDOR_STAMP)
