[settings.kubernetes]
cluster-name = "${cluster_name}"
api-server = "${cluster_endpoint}"
cluster-certificate = "${cluster_ca_data}"

# Set autoscaling wait
[settings.autoscaling]
should-wait = true

# settings.kubernetes section from bootstrap_extra_args in default template
pod-pids-limit = 1000

# The admin host container provides SSH access and runs with "superpowers".
# It is disabled by default, but can be disabled explicitly.
[settings.host-containers.admin]
enabled = false

# The control host container provides out-of-band access via SSM.
# It is enabled by default, and can be disabled if you do not expect to use SSM.
# This could leave you with no way to access the API and change settings on an existing node!
[settings.host-containers.control]
enabled = true

# extra args added
[settings.kernel]
lockdown = "integrity"

[settings.kernel.sysctl]
"user.max_user_namespaces" = "${max_namespaces}"

[settings.kubernetes.node-labels]
${node_labels}

[settings.kubernetes.node-taints]
${node_taints}
