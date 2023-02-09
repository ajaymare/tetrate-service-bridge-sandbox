data "aws_availability_zones" "available" {}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.k8s_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  create_cloudwatch_log_group     = false

  vpc_id     = var.vpc_id
  subnet_ids = var.vpc_subnets

  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = ["m5.xlarge"]
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }

    tags = merge(var.tags, {
      Name = "${var.name_prefix}_default"
    })
  }

  cluster_addons = {
    coredns = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {
    tsb_sandbox_blue = {
      min_size     = 3
      max_size     = 5
      desired_size = 3
    }
    tags = merge(var.tags, {
      Name = "${var.name_prefix}_sandbox_blue"
    })
  }

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "all"
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 0
      type                       = "egress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}"
  })

  putin_khuylo = true

}

data "aws_eks_cluster" "cluster" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

resource "local_file" "gen_kubeconfig_sh" {
  content         = "eksctl utils write-kubeconfig --cluster ${var.cluster_name} --region ${data.aws_availability_zones.available.id} --kubeconfig ${var.cluster_name}-kubeconfig"
  filename        = "${var.output_path}/generate-${var.cluster_name}-kubeconfig.sh"
  file_permission = "0755"
}