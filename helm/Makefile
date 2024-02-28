# default target for this Makefile
helm:   helm-up
.PHONY: helm

# Helm implementation

# variables
HELM?="$$(which helm)"

HELM_YAWSIR_NS?="yawsir"
HELM_YAWSIR_NAME?="yawsir"

# Pre-req checks
check-reqs:
	@export HELM="$$(which helm)"                       && \
	if [ -z "$$HELM" ] ; then                              \
	echo "[x] helm binary is missing or not in PATH"      ;\
	else                                                   \
	echo "[v] helm binary found at $${HELM}"              ;\
	fi                                                    ;\
	if [[ -z "$$HELM" ]] ; then        \
		echo "Please install the missing software and retry";\
		exit 1                                              ;\
	fi

helm-up: _helm-yawsir-up
_helm-yawsir-up:
	@cd yawsir                            && \
	${HELM} install -n ${HELM_YAWSIR_NS}     \
		-f kind_values.yaml --create-namespace \
		${HELM_YAWSIR_NAME} .

helm-down: _helm-yawsir-down
_helm-yawsir-down:
	@cd yawsir                            && \
	${HELM} uninstall -n ${HELM_YAWSIR_NS}   \
		${HELM_YAWSIR_NAME}

.PHONY: check-reqs
.PHONY: helm helm-up helm-down
.PHONY: _helm-yawsir-up _helm-yawsir-down
