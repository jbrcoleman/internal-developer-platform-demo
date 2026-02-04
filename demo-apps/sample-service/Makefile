.PHONY: build run docker-build docker-run kind-load test clean

APP_NAME=sample-service
VERSION?=v1

build:
	go build -o bin/$(APP_NAME) .

run:
	APP_VERSION=$(VERSION) go run .

test:
	go test -v ./...

docker-build:
	docker build -t $(APP_NAME):$(VERSION) .

docker-run:
	docker run -p 8080:8080 -e APP_VERSION=$(VERSION) $(APP_NAME):$(VERSION)

# For kind cluster
kind-load:
	docker build -t $(APP_NAME):$(VERSION) .
	kind load docker-image $(APP_NAME):$(VERSION) --name platform-demo

# Build and load all versions
all-versions:
	$(MAKE) kind-load VERSION=v1
	$(MAKE) kind-load VERSION=v2
	$(MAKE) kind-load VERSION=v2-bad
	$(MAKE) kind-load VERSION=v3-slow

clean:
	rm -rf bin/
