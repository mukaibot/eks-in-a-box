# EKS-in-a-box
_The easy way to spin up Kubernetes at REA_

# About
EKS-in-a-box is a Ruby program that will give you your own non-production EKS cluster in about 20 minutes by issuing a single command!

* Creates a VPC with a bastion using rea-vpc
* Creates the cluster for you
* Installs EKS-vendored versions of the binaries you need (kubectl, heptio aws authenticator) if you don't have them
* Writes a kube-config for you

EKS-in-a-box only uses native Ruby functionality and does not require any Gem dependencies. Cool!

## Dependencies
* aws cli tool
* git (configured with SSH Key access)
* ruby (whatever OS-X includes is fine)

## Usage
Create a new EKS cluster in us-west-2

`rea-as saml REAio bin/eks-box # will prompt you for cluster name`

The stacks will be named according to your cluster name, eg if you enter `my-cluster` as the name, the script will create:

* VPC stack called `my-cluster-vpc`
* VPC access stack called `my-cluster-access`
* VPC NAT stack called `my-cluster-vpc-nat`
* VPC Bastion stack called `my-cluster-vpc-bastion`
* EKS cluster node stack called `my-cluster-nodes`
* EKS cluster called `my-cluster`

## Dev notes
This is some of the worst Ruby code I've written - Timothy
