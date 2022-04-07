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

# for ((i=0; i<$#; i=i+2)); do
# 	j=i+1
#   create_eni_by_subnet_az ${argv[i]} ${argv[j]}
# done

#   # Create ENI resources
# create_eni_by_subnet_az us-east-1a subnet-0d1721ee67b8e86f2
# create_eni_by_subnet_az us-east-1b subnet-0f4fca0c09833be0e
# create_eni_by_subnet_az us-east-1c subnet-0a3edf8eea91b3cca

# aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filter "Name=tag:Name,Values=${cluster_name}-general" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[InstanceId]" --output text) --output text

