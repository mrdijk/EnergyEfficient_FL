#!/bin/bash
DYNAMOS_ROOT="${HOME}/EnergyEfficiencient_FL"
SCRIPTS="${DYNAMOS_ROOT}/energy-efficiency/scripts"

{
  echo echo "TTP: $1"
  echo ""

if [ -z "$1" ]; then
  echo "No thirdparty name provided."
  exit 1
fi

sed -e "s/^# //" -e "s/%THIRDPARTY%/$1/g" "${DYNAMOS_ROOT}/charts/thirdparty/templates/thirdpartyX.yaml" > "charts/thirdparty/templates/${1}.yaml"

if ! grep -q "namespace: $1" ${DYNAMOS_ROOT}/charts/thirdparty/templates/cluster_role.yaml; then

if grep -q "apiVersion:" charts/thirdparty/templates/cluster_role.yaml; then
tee -a charts/thirdparty/templates/cluster_role.yaml << END
---

END
fi

tee -a charts/thirdparty/templates/cluster_role.yaml << END
apiVersion: v1
kind: ServiceAccount
metadata:
  name: job-creator-$1
  namespace: $1

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: job-creator-$1
  namespace: $1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: job-creator
subjects:
- kind: ServiceAccount
  name: job-creator-$1
  namespace: $1
END
fi

${SCRIPTS}/add_namespace.sh $1

}
