# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 14.1.2
* bugfix: correct issue when no hosts are provided

## 14.1.1
* bugfix: only create shared alb listener rule when shared alb is created

## 14.1.0

* security: Change the default Shared ALB configuration to deny access by default until the allowed hostnames are configured
* feat: allow cron overrides for startup/shutdown schedules

## 14.0.1

* bugfix: Pin vpc_cni_irsa module to 5.33 to avoid breaking aws provider change

## 14.0.0
* Add precommit ci
* Apply fixes from pre-commit
* Fix fixes from pre-commit
* Fix fix for fixes from pre-commit
* Upgrade to EKS 1.27

## 13.4.0

* feat: allow cron overrides for startup/shutdown schedules

## 13.3.4

* bugfix: Pin vpc_cni_irsa module to 5.33 to avoid breaking aws provider change

## 13.3.1

* Attach waf to shared alb

## 13.3.0

* Adding variable to support custom IAM policy attachments
