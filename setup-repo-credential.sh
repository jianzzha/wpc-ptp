REGISTRY=${REGISTRY:-""}
REGISTRY_CERT=${REGISTRY_CERT:-""}

if [[ -z ${REGISTRY} || -z ${REGISTRY_CERT} ]]; then
   echo "The environment variable REGISTRY and REGISTRY_CERT must be set."
   exit 1
fi

OPENSHIFT_SECRET_FILE=pull-secrets.json
oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' > ${OPENSHIFT_SECRET_FILE}
REGISTRY_USER=${REGISTRY_USER:-""}
REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-""}
if [[ -n ${REGISTRY_USER} && -n ${REGISTRY_PASSWORD} ]]; then
    oc registry login --skip-check --registry="${REGISTRY}" --auth-basic="${REGISTRY_USER}:${REGISTRY_PASSWORD}" --to=${OPENSHIFT_SECRET_FILE}
    oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=${OPENSHIFT_SECRET_FILE}
fi

REGISTRY_CERT=${REGISTRY_CERT:-""}
if [[ -n ${REGISTRY_CERT} && -f ${REGISTRY_CERT} ]]; then
    oc delete configmap registry-cas -n openshift-config 2>/dev/null || true
    oc create configmap registry-cas -n openshift-config --from-file=$(echo ${REGISTRY} | sed 's/:/../')=${REGISTRY_CERT}
    oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge
fi

