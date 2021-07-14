#!/usr/bin/make
SHELL = /bin/sh

docker_bin := $(shell command -v docker 2> /dev/null)
docker_compose_bin := $(shell command -v docker-compose 2> /dev/null)

REGISTRY_HOST = registry.hub.docker.com
REGISTRY_PATH = vtikunov/php
IMAGES_PREFIX := $(shell basename $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))
PUBLISH_TAGS = latest
PULL_TAG = latest
IMAGE = $(REGISTRY_HOST)/$(REGISTRY_PATH)
IMAGE_LOCAL_TAG = $(IMAGES_PREFIX)_php-cli
IMAGE_DOCKERFILE = ./src/Dockerfile
IMAGE_CONTEXT = ./src
CONTAINER_NAME := php-cli

all_images = $(IMAGE) \
             $(IMAGE_LOCAL_TAG)

ifeq "$(REGISTRY_HOST)" "registry.hub.docker.com"
	docker_login_hint ?= "\n\
	**************************************************************************************\n\
	* Make your own auth token here: <https://registry.hub.docker.com/settings/security> *\n\
	**************************************************************************************\n"
endif

.PHONY : help pull build push login clean\
		 up down restart \
		 php shell install update \
		 test
.DEFAULT_GOAL := help

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo "\n  Allowed for overriding next properties:\n\n\
	    PULL_TAG - Tag for pulling images before building own\n\
	              ('latest' by default)\n\
	    PUBLISH_TAGS - Tags list for building and pushing into remote registry\n\
	                   (delimiter - single space, 'latest' by default)\n\n\
	  Usage example:\n\
	    make PULL_TAG='v1.2.3' PUBLISH_TAGS='latest v1.2.3 test-tag' push"

pull:
	-$(docker_bin) pull "$(IMAGE):$(PULL_TAG)"

build: pull
	$(docker_bin) build \
	  --cache-from "$(IMAGE):$(PULL_TAG)" \
	  --tag "$(IMAGE_LOCAL_TAG)" \
	  -f $(IMAGE_DOCKERFILE) $(IMAGE_CONTEXT)

push: pull
	$(docker_bin) build \
	  --cache-from "$(IMAGE):$(PULL_TAG)" \
	  $(foreach tag_name,$(PUBLISH_TAGS),--tag "$(IMAGE):$(tag_name)") \
	  -f $(IMAGE_DOCKERFILE) $(IMAGE_CONTEXT);
	$(foreach tag_name,$(PUBLISH_TAGS),$(docker_bin) push "$(IMAGE):$(tag_name)";)

login:
	@echo $(docker_login_hint)
	$(docker_bin) login $(REGISTRY_HOST)

clean:
	-$(docker_compose_bin) down -v
	$(foreach image,$(all_images),$(docker_bin) rmi -f $(image);)

up:
	$(docker_compose_bin) up --no-recreate -d

down:
	$(docker_compose_bin) down

restart: up
	$(docker_compose_bin) restart

php: up
	$(docker_compose_bin) exec -u $(shell id -u) $(CONTAINER_NAME) php $(ARGS)

shell: up
	$(docker_compose_bin) exec -u $(shell id -u) $(CONTAINER_NAME) sh

install: up
	$(docker_compose_bin) exec -u $(shell id -u) $(CONTAINER_NAME) composer install --no-interaction --ansi --no-suggest

update: up
	$(docker_compose_bin) exec -u $(shell id -u) $(CONTAINER_NAME) composer update --no-interaction --ansi --no-suggest

test: up
	$(docker_compose_bin) exec -u $(shell id -u) $(CONTAINER_NAME) composer test
