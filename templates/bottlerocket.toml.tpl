# settings.kubernetes section from bootstrap_extra_args in default template
pod-pids-limit = ${pod_pids_limit}

# Set autoscaling wait
[settings.autoscaling]
should-wait = true

# The admin host container provides SSH access and runs with "superpowers".
# It is disabled by default, but can be enabled explicitly.
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

%{ if length(node_labels) > 0 ~}
[settings.kubernetes.node-labels]
%{ for label_key, label_value in node_labels ~}
"${label_key}" = "${label_value}"
%{ endfor ~}
%{ endif ~}

%{ if length(node_taints) > 0 ~}
[settings.kubernetes.node-taints]
%{ for taint in node_taints ~}
"${taint.key}" = "${taint.value}:${taint.effect}"
%{ endfor ~}
%{ endif ~}
