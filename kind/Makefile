kind: kind-up
.PHONY: kind

# KIND implementation

# variables
KIND?="$$(which kind)"

KIND_CLUSTER?=yawsir-on-k8s

# Pre-req checks
check-reqs:
	@export KIND="$$(which kind)"                       && \
	if [ -z "$$KIND" ] ; then                              \
	echo "[x] kind binary is missing or not in PATH"      ;\
	else                                                   \
	echo "[v] kind binary found at $${KIND}"              ;\
	fi                                                    ;\
	if [[ -z "$$KIND" ]] ; then        \
		echo "Please install the missing software and retry";\
		exit 1                                              ;\
	fi

kind-up: check-reqs
	@${KIND} create cluster       \
		--name ${KIND_CLUSTER}      \
		--config ./kind-config.yaml

kind-down: check-reqs
	@${KIND} delete cluster       \
		--name ${KIND_CLUSTER}

.PHONY: kind check-reqs
.PHONY: kind-up kind-down
