GIT_TAG = $(shell git describe --tags --always --abbrev=0)
ifeq "$(shell git rev-list HEAD ^${GIT_TAG} | wc -l)" "0"
VERSION ?= ${GIT_TAG}
else
GIT_COMMIT = $(shell git show -s --pretty="format:%cd-%<(14,trunc)%H" --date=format:%Y%m%d%H%M%S --abbrev=0 | sed 's/\.\.//g')
VERSION ?= ${GIT_TAG}-${GIT_COMMIT}
endif
export VERSION

REGISTRY ?= registry.smtx.io/
IMG = $(REGISTRY)sfs/autoheal:$(VERSION)
CONTAINER_TOOL ?= docker
PLATFORMS ?= linux/arm64,linux/amd64

.PHONY: all
all: build

build:  ## Build docker image with the manager.
	sed -e '1 s/\(^FROM\)/FROM --platform=\$$\{BUILDPLATFORM\}/; t' -e ' 1,// s//FROM --platform=\$$\{BUILDPLATFORM\}/' Dockerfile > Dockerfile.cross
	$(CONTAINER_TOOL) buildx create --name project-v3-builder
	$(CONTAINER_TOOL) buildx use project-v3-builder
	$(CONTAINER_TOOL) buildx build \
		--platform=$(PLATFORMS) \
		--tag ${IMG} \
		--build-arg REGISTRY=$(REGISTRY) \
		-f Dockerfile.cross . \
		--push 
	$(CONTAINER_TOOL) buildx rm project-v3-builder
	rm Dockerfile.cross