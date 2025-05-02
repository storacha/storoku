# Storoku

> Terraform Modules For Conventional Storacha Service Deployments

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Deployment](#deployment)
- [Contribute](#contribute)
- [License](#license)

## Overview

This is a collection of resuable and interoperable terraform modules that standardize AWS deployments on Storacha

They're designed to:
- save you tons of time on writing terraform deployments
- use sensible defaults
- keep things secure and using best practices (uniformity = less chances to mess it up)
- deploy things in a cost effective way, without compromising ease of use

Things you can setup with Storoku:
- PostgreSQL databases
- Redis caches
- SQS Queues
- DynamoDB tables
- SNS Topics
- Your application running in a scalable ECS cluster, connected to the services you expect.

## Installation

First, install OpenTofu (OpenTofu is a fork of Terraform that retains a full open source license -- please use OpenTofu when deploying Storacha services in order to avoid licensing issues).

```terminal
brew update
brew install opentofu
tofu -u version
```

Then install Storoku

```terminal
brew install storacha/storoku
```

# Usage

