locals {
  oidc_provider =  trimprefix(var.oidc_issuer, "https://")
}

# Trust policy to enable IRSA
data "aws_iam_policy_document" "irsa_trust_policy" {
    statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"
      ]
    }

    condition {
      test = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values = [
        "system:serviceaccount:${var.csi_namespace}:${var.csi_service_account}"
      ]
    }
  }
}

# Policy Document for IAM policy.
# Retrieved from https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/v1.4.0/docs/example-iam-policy.json
data "aws_iam_policy_document" "ebs_csi_policy_document" {
    # The role created with this policy is to be assumed by the pod via IRSA
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateSnapshot",
            "ec2:AttachVolume",
            "ec2:DetachVolume",
            "ec2:ModifyVolume",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInstances",
            "ec2:DescribeSnapshots",
            "ec2:DescribeTags",
            "ec2:DescribeVolumes",
            "ec2:DescribeVolumesModifications"
        ]
        resources = ["*"]
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateTags"
        ]
        resources = [
            "arn:aws:ec2:*:*:volume/*",
            "arn:aws:ec2:*:*:snapshot/*"
        ]
        condition {
            test = "StringEquals"
            variable = "ec2:CreateAction"
            values = [
                    "CreateVolume",
                    "CreateSnapshot"
            ]
        }
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:DeleteTags"
        ]
        resources = [
            "arn:aws:ec2:*:*:volume/*",
            "arn:aws:ec2:*:*:snapshot/*"
        ]
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateVolume"
        ]
        resources = ["*"]
        condition {
            test = "StringLike"
            variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
            values = ["true"]
        }
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateVolume"
        ]
        resources = ["*"]
        condition {
            test = "StringLike"
            variable = "aws:RequestTag/CSIVolumeName"
            values = ["*"]
        }
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateVolume"
        ]
        resources = ["*"]
        condition {
            test = "StringLike"
            variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
            values = ["owned"]
         }
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:DeleteVolume"
        ]
        resources = ["*"]
        condition {
            test = "StringLike"
            variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
            values = ["true"]
        }
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:DeleteVolume"
        ]
        resources = ["*"]
        condition {
            test = "StringLike"
            variable = "ec2:ResourceTag/CSIVolumeName"
            values = ["*"]
        }
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:DeleteVolume"
        ]
        resources = ["*"]
        condition {
            test = "StringLike"
            variable = "ec2:ResourceTag/kubernetes.io/cluster/*"
            values = ["owned"]
        }
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:DeleteSnapshot"
        ]
        resources = ["*"]
        condition {
            test = "StringLike"
            variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
            values = ["*"]
        }
    }

    statement {
        effect = "Allow"
        actions = [
            "ec2:DeleteSnapshot"
        ]
        resources = ["*"]
        condition {
            test = "StringLike"
            variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
            values = ["true"]
        }
    }
}

# Create IAM policy
resource "aws_iam_role_policy" "ebs_csi_policy" {
    role = aws_iam_role.ebs_csi_role.name
    policy = data.aws_iam_policy_document.ebs_csi_policy_document.json
}

# Create IAM role to be used by CSI driver pods with the trust policy
resource "aws_iam_role" "ebs_csi_role" {
  name_prefix = "Proj-ebs-csi-"
  description = "Role to enable csi-driver pods to manage EBS resources via IRSA in EKS cluster ${var.cluster_name}"
  permissions_boundary = "arn:aws:iam::aws:policy/PowerUserAccess"
  assume_role_policy = data.aws_iam_policy_document.irsa_trust_policy.json
}