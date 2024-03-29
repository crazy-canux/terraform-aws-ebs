variable "cluster_name" {
  description = "k8s cluster name"
  type        = string
}

variable "oidc_issuer" {
  description = "OIDC provider, leave in blank for EKS clusters"
  type        = string
  default     = null
}

variable "csi_namespace" {
  description = "EBS CSI namespace"
  type        = string
  default     = "kube-system"
}

variable "csi_service_account" {
  description = "Service account to be created for use with the CSI driver"
  type        = string
  default     = "ebs-csi-controller-sa"
}

variable "csi_chart_repo_url" {
  description = "URL to repository containing the EBS CSI helm chart"
  type        = string
  default     = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
}

variable "csi_chart_version" {
  description = "EBS CSI helm chart version"
  type        = string
  default     = "2.7.0"
}

variable "ebs_volume_tags" {
  description = "Tags for EBS volumes dynamically created by the CSI driver"
  type        = map(string)
  default     = {}
}

variable "eks_default_storage_class" {
  description = "Name of storage class created by EKS by default for deletion."
  type        = string
  default     = "gp2"
}

variable "helm_values" {
  description = "Values for external-dns Helm chart in raw YAML."
  type        = list(string)
  default     = []
}

variable "extra_set_values" {
  description = "Specific values to override in the external-dns Helm chart (overrides corresponding values in the helm-value.yaml file within the module)"
  type = list(object({
    name  = string
    value = any
    type  = string
    })
  )
  default = []
}

variable "storage_class" {
  type = string
  description = "storage class name"
  default = "ebs-default"
}

variable "encrypted_storage_class" {
  type = string
  description = "encrypted storage class name"
  default = "ebs-encrypted"
}
