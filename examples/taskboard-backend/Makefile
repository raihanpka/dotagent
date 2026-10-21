.PHONY: build fmt fmt-check lint test ci

build:
	go build ./...

fmt:
	gofmt -w .

fmt-check:
	test -z "$$(gofmt -l .)"

lint:
	go vet ./...

test:
	go test -race ./...

ci: fmt-check lint build test
