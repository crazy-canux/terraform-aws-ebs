# Terraform module used to deploy ebs-csi-driver to EKS

## HowTo

how to use it:

    data "aws_eks_cluster_auth" "this" {
      name       = local.cluster_name
      provider = aws
    }

    data "aws_eks_cluster" "this" {
      name = local.cluster_name
      provider = aws
    }

    provider "aws" {
      profile = "your-aws-account"
      region  = "your-aws-region"
    }

    provider "helm" {
      kubernetes {
        host                   = data.aws_eks_cluster.this.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
        token                  = data.aws_eks_cluster_auth.this.token
      }
      alias = "ebs"
    }

    module "ebs-csi" {
      source = "git::https://github.com/crazy-canux/terraform-aws-ebs?ref=v1.0.0"
      cluster_name = "my-eks-cluster"
      csi_namespace = "kube-system"
      csi_service_account = "ebs-csi-controller-sa"
      oidc_issuer = data.aws_eks_cluster.this.identity.0.oidc.0.issuer
      ebs_volume_tags = {
        "proj" = "demo",
        "env" = "dev",
      }

      helm_values = [] 

      providers = {
        helm = helm.ebs
      }
    }
