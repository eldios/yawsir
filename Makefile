all:    full-up
.PHONY: all

# variables
ifndef SLEEP_TIME
SLEEP_TIME?="5" # time in seconds
endif

REPO_DIR?="$(shell pwd)"

KUBECTL?="$$(which kubectl)"
KUBECFG?="${REPO_DIR}/kube.config"

DOCKER?="$$(which docker)"
DOCKER_IMAGE_NAME?="eldios/yawsir"
DOCKER_IMAGE_TAG?="0.0.1"

# default aliases
up:        check-reqs kind-up helm-up
full-up:   check-reqs kind-up sleep helm-up

clean:     full-down

down:      kind-down
full-down: kind-down

# KIND implementation
include kind/Makefile

# HELM implementation
include helm/Makefile

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
	@export KIND="$$(which kind)"                     && \
	export HELM="$$(which helm)"                      && \
	export KUBECTL="$$(which kubectl)"                && \
	if [ -z "$$KIND" ] ; then                            \
	echo "[x] kind binary is missing or not in PATH"    ;\
	echo "    (kind is optional)"                       ;\
	else                                                 \
	echo "[v] kind binary found at $${KIND}"            ;\
	fi                                                  ;\
	if [ -z "$$HELM" ] ; then                            \
	echo "[X] helm binary is missing or not in PATH"    ;\
	else                                                 \
	echo "[v] helm binary found at $${HELM}"            ;\
	fi                                                  ;\
	if [ -z "$$KUBECTL" ] ; then                         \
	echo "[x] kubectl binary is missing or not in PATH" ;\
	else                                                 \
	echo "[v] kubectl binary found at $${KUBECTL}"      ;\
	fi                                                  ;\
	if [[ -z "$$KUBECTL" || -z "$$HELM" ]] ; then        \
		echo "Please install the missing binary and retry";\
		exit 1                                            ;\
	fi

# utility targets
sleep:
	@echo "sleeping ${SLEEP_TIME}s to let Kubernetes settle..."
	@sleep ${SLEEP_TIME}

config:
	@echo "# if you can read this, you should instead run:"
	@echo "#     eval \$$(make config | grep -v '^[#]')"
	@echo "export    KUBECONFIG=\"${KUBECFG}\";"

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
	@echo "kind-up          - target -> sets up a new Kind Kubernetes in Docker"
	@echo ""
	@echo "helm             - alias  -> helm-up"
	@echo "helm-up          - alias  -> helm-yawsir-up"
	@echo ""
	@echo "helm-yawsir-up   - target -> installs the Helm Chart stored in helm/yawsir to setup"
	@echo ""
	@echo "# Build targets"
	@echo ""
	@echo "docker-build     - target -> build the Docker image"
	@echo "build            - alias  -> docker-build"
	@echo ""
	@echo "# Publish targets"
	@echo "docker-push      - target -> publish the Docker image"
	@echo "push             - alias  -> docker-push"
	@echo ""
	@echo "# Uninstall/Cleaning targets"
	@echo ""
	@echo "clean            - alias  -> full-down"
	@echo "down             - alias  -> kind-down"
	@echo "full-down        - alias  -> kind-down"
	@echo ""
	@echo "kind-down        - target -> tears down the Kind Kubernetes running in Docker"
	@echo ""
	@echo "helm-down        - alias  -> helm-yawsir-down"
	@echo ""
	@echo "helm-yawsir-down - target -> uninstalls the 'yawsir' Helm Chart"
	@echo ""
	@echo "# Utility/Internal targets"
	@echo ""
	@echo "config           - target -> outputs a series of config and aliases needed"
	@echo "                          -> to interact with the installation setup"
	@echo "                          -> usage: eval \$$(make config | grep -v '^[#]')"
	@echo ""
	@echo "sleep            - target -> utility target used to delay following actions"
	@echo ""
	@echo "help             - target -> prints this help message"
	@echo ""

.PHONY: up clean down help
.PHONY: build cargo-build docker-build
.PHONY: cargo cargo-test cargo-build cargo-run
.PHONY: docker docker-build
.PHONY: sleep config
