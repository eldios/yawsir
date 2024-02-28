all:    full-up
.PHONY: all

# variables
ifndef SLEEP_TIME
SLEEP_TIME?="5" # time in seconds
endif

REPO_DIR?="$(shell pwd)"

KUBECTL?="$$(which kubectl)"

DOCKER?="$$(which docker)"
DOCKER_IMAGE_NAME?="eldios/yawsir"
DOCKER_IMAGE_TAG?="latest"

# default aliases
up:        check-reqs kind-up helm-up
full-up:   check-reqs kind-up sleep helm-up

clean:     full-down

down:      kind-down
full-down: kind-down

# KIND implementation
kind: kind-up
kind-up:
	@cd ${REPO_DIR}/kind && \
	make kind-up

kind-down:
	@cd ${REPO_DIR}/kind && \
	make kind-down

# HELM implementation
helm: helm-up
helm-up:
	@cd ${REPO_DIR}/helm && \
	make helm-up

helm-down:
	@cd ${REPO_DIR}/helm && \
	make helm-down

# build targets
build: docker-build

docker: docker-build
docker-build:
	 ${DOCKER} build                              \
	  -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
		.
docker-build-no-cache:
	 ${DOCKER} build --no-cache                   \
	  -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
		.

# Pre-req checks
check-reqs:
	@export KIND="$$(which kind)"                       && \
	export HELM="$$(which helm)"                        && \
	export KUBECTL="$$(which kubectl)"                  && \
	if [ -z "$$KIND" ] ; then                              \
	echo "[x] kind binary is missing or not in PATH"      ;\
	echo "    (kind is optional)"                         ;\
	else                                                   \
	echo "[v] kind binary found at $${KIND}"              ;\
	fi                                                    ;\
	if [ -z "$$HELM" ] ; then                              \
	echo "[X] helm binary is missing or not in PATH"      ;\
	else                                                   \
	echo "[v] helm binary found at $${HELM}"              ;\
	fi                                                    ;\
	if [ -z "$$KUBECTL" ] ; then                           \
	echo "[x] kubectl binary is missing or not in PATH"   ;\
	else                                                   \
	echo "[v] kubectl binary found at $${KUBECTL}"        ;\
	fi                                                    ;\
	if [[ -z "$$KUBECTL" || -z "$$HELM" ]] ; then          \
		echo "Please install the missing software and retry";\
		exit 1                                              ;\
	fi

# utility targets
sleep:
	@echo "sleeping ${SLEEP_TIME}s to let Kubernetes settle..."
	@sleep ${SLEEP_TIME}

help:
	@echo ""
	@echo "################################################################################"
	@echo "#      yawsir (Yet Another Web Server in Rust)- app w/ Helm, Kind and AWS      #"
	@echo "################################################################################"
	@echo ""
	@echo "# Install/Setup targets"
	@echo ""
	@echo "all              - alias  -> full-up"
	@echo ""
	@echo "up               - alias  -> kind-up"
	@echo "full-up          - alias  -> kind-up sleep helm-up"
	@echo ""
	@echo "kind             - alias  -> kind-up"
	@echo "kind-up          - target -> sets up a new KIND - Kubernetes IN Docker"
	@echo ""
	@echo "helm             - alias  -> helm-up"
	@echo "helm-up          - alias  -> installs app via Helm Chart"
	@echo ""
	@echo "# Build targets"
	@echo ""
	@echo "docker-build     - target -> build the Docker image"
	@echo "build            - alias  -> docker-build"
	@echo ""
	@echo "# Uninstall/Cleaning targets"
	@echo ""
	@echo "clean            - alias  -> full-down"
	@echo "down             - alias  -> kind-down"
	@echo "full-down        - alias  -> kind-down"
	@echo ""
	@echo "kind-down        - target -> tears down the Kind Kubernetes running in Docker"
	@echo ""
	@echo "helm-down        - alias  -> uninstalls the 'yawsir' Helm Chart"
	@echo ""
	@echo "# Utility/Internal targets"
	@echo ""
	@echo "sleep            - target -> utility target used to delay following actions"
	@echo ""
	@echo "help             - target -> prints this help message"
	@echo ""

.PHONY: up clean down help
.PHONY: build cargo-build docker-build
.PHONY: cargo cargo-test cargo-build cargo-run
.PHONY: docker docker-build
.PHONY: sleep
