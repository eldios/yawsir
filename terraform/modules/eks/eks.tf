#------------------------------------------------------------------------------
# EKS SETUP
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
# https://github.com/terraform-aws-modules/terraform-aws-eks/
#------------------------------------------------------------------------------

################################################################################
# EBS CSI ROLE
################################################################################

locals {
  ebs_csi_service_account_namespace = "kube-system"
  ebs_csi_service_account_name      = "ebs-csi-controller-sa"
}

module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  attach_ebs_csi_policy = true

  create_role = true
  role_name   = "${var.name}-ebs-csi-controller"

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.4.0"

  cluster_name                   = var.name
  cluster_version                = var.eks_cluster_version
  cluster_endpoint_public_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Fargate profiles use the cluster primary security group
  # so these are not utilized
  create_cluster_security_group = false
  create_node_security_group    = false

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
  access_entries = {
    # Lele - always set myself as the ClusterAdmin
    lele = {
      principal_arn     = "arn:aws:iam::911363277838:user/lele-eks"
      kubernetes_groups = []
      policy_associations = {
        # namespaced access policies
        #admin = {
        #  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
        #  access_scope = {
        #    namespaces = [
        #      "default"
        #    ]
        #    type = "namespace"
        #  }
        #}
        # cluster-wide access policies
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  fargate_profiles = {
    karpenter = {
      selectors = [
        { namespace = "karpenter" }
      ]
    }
    kube-system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        computeType = "fargate"
        # Ensure that we fully utilize the minimum amount of resources that are supplied by
        # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
        # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
        # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
        # compute configuration that most closely matches the sum of vCPU and memory requests in
        # order to ensure pods always have the resources that they need to run.
        resources = {
          limits = {
            cpu = "0.25"
            # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
          requests = {
            cpu = "0.25"
            # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }


  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.name
  })
}

# can see a list of available addons at:
# https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest
module "eks_blueprints_addons" {
  #checkov:skip=CKV_TF_1: "Use commit instead when pinning modules"
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.15.1"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_external_secrets = true
  enable_metrics_server   = true

  enable_argocd = true
  argocd = {
    values = [jsonencode({
      domain = "argo.k8s.lele.rip"
    })]
  }

  enable_cert_manager = true
  cert_manager = {
    namespace       = "cert-manager"
    create_namspace = true
  }

  enable_external_dns = var.external_dns
  external_dns = {
    values = [jsonencode({
      provider           = "cloudflare"
      domain-filter      = "k8s.lele.rip"
      policy             = "sync"
      cloudflare-proxied = true
      env = [
        {
          name  = "CF_API_TOKEN"
          value = var.cloudflare_token
        }
      ]
    })]
  }

  enable_kube_prometheus_stack = true
  kube_prometheus_stack = {
    values = [jsonencode({
      prometheus-node-exporter = {
        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [{
                matchExpressions = [{
                  key      = "eks.amazonaws.com/compute-type"
                  operator = "NotIn"
                  values   = ["fargate"]
                }]
              }]
            }
          }
        }
      }
    })]
  }

  enable_aws_load_balancer_controller = true
  # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/deploy/configurations/
  # https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller
  aws_load_balancer_controller = {
    values = [
      "region: ${var.region}",
      "vpcId: ${module.vpc.vpc_id}",
    ]
  }

  tags = local.tags
}

################################################################################
# OpenEBS local path provisioner
################################################################################

resource "helm_release" "openebs" {
  count            = var.install_openebs ? 1 : 0
  namespace        = "openebs"
  create_namespace = true

  name       = "openebs"
  repository = "https://openebs.github.io/charts"
  chart      = "openebs"
  version    = "3.9.0"

  set {
    name  = "ndm.enabled"
    value = "false"
  }
  set {
    name  = "ndmOperator.enabled"
    value = "false"
  }
  set {
    name  = "snapshotOperator.enabled"
    value = "false"
  }
  set {
    name  = "webhook.enabled"
    value = "false"
  }
  set {
    name  = "localprovisioner.enableDeviceClass"
    value = "false"
  }
  set {
    name  = "localprovisioner.hostpathClass.name"
    value = "standard"
  }

  depends_on = [
    module.eks
  ]
}

################################################################################
# Karpenter
################################################################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.4.0"

  cluster_name           = module.eks.cluster_name
  enable_irsa            = true
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  name                = "karpenter"
  chart               = "karpenter"
  version             = "v0.34.0"

  values = [
    <<-EOM
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueueName: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    EOM
  ]
}

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: [ ${join(",", formatlist("%#v", flatten(var.instance_category)))} ]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: [ ${join(",", formatlist("%#v", flatten(var.instance_cpu)))} ]
            - key: "karpenter.k8s.aws/instance-memory"
              operator: In
              values: [ ${join(",", formatlist("%#v", flatten(var.instance_memory)))} ]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: [ "5" ]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
            # If not included, the webhook for the AWS cloud provider
            # will default to on-demand only
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["spot"]
          # Karpenter provides the ability to specify a few additional Kubelet args.
          # These are all optional and provide support for additional customization and use cases.
          kubelet:
            systemReserved:
              cpu: 100m
              memory: 100Mi
              ephemeral-storage: 1Gi
            kubeReserved:
              cpu: 200m
              memory: 100Mi
              ephemeral-storage: 3Gi
            evictionHard:
              memory.available:  50Mi
              nodefs.available:  1%
              nodefs.inodesFree: 1%
            evictionSoft:
              memory.available:  3%
              nodefs.available:  3%
              nodefs.inodesFree: 3%
            evictionSoftGracePeriod:
              memory.available:  10m
              nodefs.available:  10m
              nodefs.inodesFree: 20m
            evictionMaxPodGracePeriod:   60
            imageGCHighThresholdPercent: 95
            imageGCLowThresholdPercent:  90
            cpuCFSQuota: true
            #podsPerCore: 2
            #maxPods: 20

      disrupition:
        consolidationPolicy: WhenUnderutilized | WhenEmpty
        consolidationAfter: 30s
        expireAfter: 720h

      # Priority given to the provisioner when the scheduler considers which provisioner
      # to select. Higher weights indicate higher priority when comparing provisioners.
      # Specifying no weight is equivalent to specifying a weight of 0.
      weight: 10

      # Resource limits constrain the total size of the cluster.
      # Limits prevent Karpenter from creating new instances once 
      # the limit is exceeded.
      limits:
        cpu:    "${var.cluster_cpu}"
        memory: "${var.cluster_memory}"

  YAML

  depends_on = [
    module.eks
  ]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      role: ${module.karpenter.node_iam_role_name}
      amiFamily: AL2
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: ${var.instance_disk_space}
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
 YAML

  depends_on = [
    module.eks
  ]
}

################################################################################
# SSM Fetch DataDog Agent Key and site
################################################################################

data "aws_ssm_parameter" "datadog_site" {
  count = var.install_datadog_agent ? 1 : 0
  name  = "/datadog/${var.env}/site"
}

data "aws_ssm_parameter" "datadog_api_key" {
  count = var.install_datadog_agent ? 1 : 0
  name  = "/datadog/${var.env}/api_key"
}

################################################################################
# DataDog Agent
################################################################################

resource "helm_release" "datadog_agent" {
  count            = var.install_datadog_agent ? 1 : 0
  namespace        = "monitoring"
  create_namespace = true

  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"

  set {
    name  = "datadog.apiKey"
    value = data.aws_ssm_parameter.datadog_api_key[0].value
  }

  set {
    name  = "datadog.site"
    value = data.aws_ssm_parameter.datadog_site[0].value
  }

  set {
    name  = "clusterAgent.enabled"
    value = "true"
  }

  set {
    name  = "clusterAgent.metricsProvider.enabled"
    value = "true"
  }

  set {
    name  = "clusterAgent.admissionController.enabled"
    value = "true"
  }

  set {
    name  = "clusterAgent.admissioncontroller.mutateUnlabelled"
    value = "true"
  }

  set {
    name  = "datadog.apm.enabled"
    value = "true"
  }

  set {
    name  = "datadog.logs.enabled"
    value = "true"
  }

  set {
    name  = "datadog.logs.containerCollectAll"
    value = "true"
  }

  set {
    name  = "datadog.containerExcludeLogs"
    value = local.exclude_image_list
  }

  set {
    name  = "datadog.env[0].name"
    value = "DD_ENV"
  }

  set {
    name  = "datadog.env[0].value"
    value = var.env
  }

  set {
    name  = "datadog.env[1].name"
    value = "DD_CLUSTER_NAME"
  }

  set {
    name  = "datadog.env[1].value"
    value = var.name
  }
}
