##############################
# data and local variable 
##############################
locals {
  kubeconfig = <<-EOT
    apiVersion: v1
    clusters:
    - cluster:
        server: "${data.aws_eks_cluster.this.endpoint}"
        certificate-authority-data: ${data.aws_eks_cluster.this.certificate_authority.0.data}
      name: kubernetes
    contexts:
        - context:
            cluster: kubernetes
            user: aws
          name: aws
    current-context: aws
    kind: Config
    preferences: {}
    users:
    - name: aws
      user:
        exec:
            apiVersion: client.authentication.k8s.io/v1alpha1
            command: aws
            env: null
            args:
            - "--region"
            - "${data.aws_region.this.name}"
            - "eks"
            - "get-token"
            - "--cluster-name"
            - "${var.cluster_name}"
    EOT
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_region" "this" {}

##############################
# module and resources
##############################
# Deploy CSI driver helm chart
resource "helm_release" "ebs-csi" {
  name       = "ebs-csi"
  repository = var.csi_chart_repo_url
  chart      = "aws-ebs-csi-driver"
  version    = var.csi_chart_version
  namespace  = var.csi_namespace
  values     = length(var.helm_values) > 0 ? var.helm_values : ["${file("${path.module}/helm-values.yaml")}"]

  # Set volume tags
  dynamic "set" {
    for_each = var.ebs_volume_tags
    content {
      name  = "controller.extraVolumeTags.${set.key}"
      value = set.value
    }
  }

  # Set any extra values provided by the user
  dynamic "set" {
    for_each = var.extra_set_values
    content {
      name  = set.value.name
      value = set.value.value
      type  = set.value.type
    }
  }

  # Set ebs-csi service account name and IAM role annotaion
  set {
    name  = "controller.serviceAccount.name"
    value = var.csi_service_account
  }
  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ebs_csi_role.arn
  }
}

# Delete default Storage Class added by EKS 
resource "null_resource" "delete_default_storage_class" {
  provisioner "local-exec" {
    command = <<-EOT
    kubectl delete sc ${var.eks_default_storage_class} --kubeconfig <(echo $KUBECONFIG | base64 --decode)
    EOT

    interpreter = ["/bin/bash", "-c"]

    environment = {
      KUBECONFIG = base64encode(local.kubeconfig)
    }
  }

  depends_on = [
    helm_release.ebs-csi
  ]
}
