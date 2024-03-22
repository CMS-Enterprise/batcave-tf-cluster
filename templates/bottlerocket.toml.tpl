# settings.kubernetes section from bootstrap_extra_args in default template
pod-pids-limit = 1000

# Set autoscaling wait
[settings.autoscaling]
should-wait = true

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
