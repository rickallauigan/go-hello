.PHONY: all

DEPS := $(wildcard *.go)
BUILD_IMAGE := "hello-world-build"
PRODUCTION_IMAGE := "hello-world"
PRODUCTION_NAME := "hello-production"
DEPLOY_ACCOUNT := "appleboy"
export PROJECT_PATH = /go/src/github.com/appleboy/go-hello

all: build server

install:
	glide install

update:
	glide update

build:
	docker build -t $(BUILD_IMAGE) -f Dockerfile.build .
	docker run $(BUILD_IMAGE) > build.tar.gz
	docker build -t $(PRODUCTION_IMAGE) -f Dockerfile.dist .

server:
	-docker rm -f hello-production
	-docker run -d -p 8088:8000 --name $(PRODUCTION_NAME) $(PRODUCTION_IMAGE)

deploy:
ifeq ($(tag),)
	@echo "Usage: make $@ tag=<tag>"
	@exit 1
endif
	docker tag -f $(PRODUCTION_IMAGE):latest $(DEPLOY_ACCOUNT)/$(PRODUCTION_IMAGE):$(tag)
	docker push $(DEPLOY_ACCOUNT)/$(PRODUCTION_IMAGE):$(tag)

hello: ${DEPS}
	GO15VENDOREXPERIMENT=1 go build

test:
	go test -v -cover

docker_compose_test: dist-clean
	docker-compose -f docker/docker-compose.yml config
	docker-compose -f docker/docker-compose.yml run golang-hello-testing
	docker-compose -f docker/docker-compose.yml down

docker_test: dist-clean
	docker run --rm \
		-v $(PWD):$(PROJECT_PATH) \
		-w=$(PROJECT_PATH) \
		appleboy/golang-testing \
		sh -c "make install && coverage all"

clean:
	-rm -rf .cover
	-rm -rf build.tar.gz

dist-clean: clean
	-docker rmi -f $(BUILD_IMAGE)
	-docker rm -f $(PRODUCTION_NAME)
	-docker rmi -f $(PRODUCTION_IMAGE)
	-docker-compose -f docker/docker-compose.yml down
