node_sg=$1

function create_eni_by_subnet_az(){
   subnet_az=${1}
   subnet_id=${2}
   cat <<EOF | kubectl apply -f -
 apiVersion: crd.k8s.amazonaws.com/v1alpha1
 kind: ENIConfig
 metadata:
  name: ${subnet_az}
 spec:
  subnet: "${subnet_id}"
  securityGroups:
   - ${node_sg}
EOF
}

create_eni_by_subnet_az $2 $3
