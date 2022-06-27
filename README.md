# terraform-aws-ebs

## HowTo

how to use it:

    module "ebs_csi" {
      source              = "git::https://github.com/crazy-canux/terraform-aws-ebs.git?ref=v1.0.0"
      cluster_name        = local.cluster_name
      csi_namespace       = "kube-system"
      csi_service_account = "ebs-csi-controller-sa"
      oidc_issuer         = local.cluster_oidc_issuer_url
      ebs_volume_tags     = local.tags
      csi_chart_version   = local.chart_version
      helm_values         = ["${file("${path.module}/helm-values.yaml")}"]
      depends_on          = [data.terraform_remote_state.eks]
    }
