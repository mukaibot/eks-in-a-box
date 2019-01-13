[![Build status](https://badge.buildkite.com/e67d4c9dd6ba25899858b56f348d6f15cc9c71922910bddab7.svg)](https://buildkite.com/rea/eks-in-a-box)

# EKS-in-a-box
_The easy way to spin up Kubernetes at REA_

# About
EKS-in-a-box is a Ruby program that will give you your own EKS cluster, with addons that make it actually useful. This is the server component to using REA Shipper and Kubernetes.

Here's what you get:
* An EKS cluster
* An autoscaling group of nodes on a private subnet in Your VPC
* Client binaries for eksctl, kubectl, IAM authenticator and Helm
* The Helm package manager
* Metrics server (enables `kubectl top`)
* An Ingress controller, terminating SSL and redirecting http -> https (if you provide an ACM cert ARN)
* Cluster Autoscaler (scales nodes up and down as required)
* IAM integration (the server half of what REA Shipper needs to give your Pods IAM roles)
* Route 53 integration via External DNS
* Easily give additional IAM roles access to your cluster (ie for Buildkite Agents to do deployments)
* The ability to update the components on your cluster to stay in sync with EKS-in-a-box

Here's what you're getting Really Soon
* Kubernetes dashboard
* Logs straight into Splunk

EKS-in-a-box only uses native Ruby functionality and does not require any Gem dependencies. Cool!

# Installation
`gem install eks-in-a-box --source https://rubygems.delivery.realestate.com.au`

Then run the command `eks-box --help` for usage!

## Dependencies
* ruby (whatever OS-X includes is fine)
* curl
* aws cli

## Usage
*Note: `yourconfig.yml` represents the path to a configuration file you have created with the generate command.*

### View the help
Shows the usage instructions
`bin/eks-box --help`

### Download the client binaries
Downloads client binaries for kubectl, eksctl and helm. This is run automatically when you create a cluster.
`bin/eks-box --operation prereqs`

### Generate a sample config
Generates a sample configuration file that you can edit
`bin/eks-box --operation generate`

### Configure your kube config with your cluser
Once you have created a cluster, or want to access one that has already been created, you can update your local kube config with this command.
`bin/eks-box --operation write-config --config yourconfig.yml`

### Create your cluster
Create an EKS cluster from a defined configuration file
`rea-as saml YourRole bin/eks-box -o create --config yourconfig.yml`

### Keep your cluster updated
Updates your cluster to use the latest components / features of eks-in-a-box
`rea-as saml YourRole bin/eks-box -o update --config yourconfig.yml`

### Delete your cluster
Delete a cluster and clean-up
`rea-as saml YourRole bin/eks-box -o delete --config yourconfig.yml`

## How it works

EKS-in-a-box does the following:

1. Downloads client binaries to your machine for EKS and Helm
1. Uses [eksctl](https://github.com/weaveworks/eksctl) to create a cluster
1. Installs Helm
1. Adds some additional IAM policies to allow various components to work
1. Uses Helm to install charts in `lib/update/charts.rb`
