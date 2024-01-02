plugin "aws" {
  enabled = true

  version = "0.28.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_required_providers" {
  enabled = true

  # defaults
  source  = false
  version = true
}
