# default target for this Makefile
helm:   helm-up
.PHONY: helm

# Helm implementation
HELM?="$$(which helm)"
HELM_DIR?="${REPO_DIR}/helm"

HELM_YAWSIR_CHART_DIR?="${HELM_DIR}/yawsir"
HELM_YAWSIR_NS?="yawsir"
HELM_YAWSIR_NAME?="yawsir"

helm-up: helm-yawsir-up

helm-yawsir-up:
	@export KUBECONFIG="${KUBECFG}"       &&\
	export HELM_VAR_KUBECFG="${KUBECFG}"  &&\
	cd ${HELM_YAWSIR_CHART_DIR}           &&\
	${HELM} install -n ${HELM_YAWSIR_NS}    \
		-f values.yaml --create-namespace     \
		${HELM_YAWSIR_NAME} .

helm-down: helm-yawsir-down

helm-yawsir-down:
	@export KUBECONFIG="${KUBECFG}"       &&\
	export HELM_VAR_KUBECFG="${KUBECFG}"  &&\
	cd ${HELM_YAWSIR_CHART_DIR}           &&\
	${HELM} uninstall -n ${HELM_YAWSIR_NS}  \
		${HELM_YAWSIR_NAME}

.PHONY: helm helm-up helm-down
.PHONY: helm-yawsir-up helm-yawsir-down
