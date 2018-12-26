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
* An Ingress controller, terminating SSL (if you provide an ACM cert ARN)
* The ability to update the components on your cluster to stay in sync with EKS-in-a-box

Here's what you're getting Really Soon
* Logs straight into Splunk
* IAM integration (the server half of what REA Shipper needs to give your Pods IAM roles)
* Route 53 integration via External DNS

EKS-in-a-box only uses native Ruby functionality and does not require any Gem dependencies. Cool!

## Dependencies
* ruby (whatever OS-X includes is fine)
* curl

## Usage
### View the help
Shows the usage instructions
`bin/eks-box --help`

### Generate a sample config
Generates a sample configuration file that you can edit
`bin/eks-box --operation generate`

### Create your cluster
Create an EKS cluster from a defined configuration file
`rea-as saml YourRole bin/eks-box -o create --config yourconfig.yml`

### Keep your cluster updated
Updates your cluster to use the latest components / features of eks-in-a-box
`rea-as saml YourRole bin/eks-box -o update --config yourconfig.yml`


