# AWS EKS Module

This reusable module creates an Amazon EKS cluster, separate cluster and node IAM roles, one managed system node group, and the `vpc-cni`, `coredns`, and `kube-proxy` managed add-ons. It accepts VPC and private subnet IDs from the calling stack and does not create networking or custom security groups.

The cluster uses EKS API access entries rather than the legacy `aws-auth` ConfigMap, standard Kubernetes version support, configurable control-plane logging, and configurable public/private API endpoint access. Both the control plane and managed node group use only the supplied private subnets.

## Node-role bootstrap policy

The node role temporarily receives `AmazonEKS_CNI_Policy` so the VPC CNI has its required AWS permissions during the initial platform bootstrap. AWS recommends moving these permissions to a dedicated IRSA or EKS Pod Identity role; that separation will be introduced later. The node role also receives `AmazonEKSWorkerNodePolicy` and `AmazonEC2ContainerRegistryPullOnly`.

The module does not create Fargate profiles, EKS Auto Mode resources, Pod Identity associations, IRSA roles, Kubernetes workloads, Argo CD, ingress controllers, load balancers, Route53 resources, or customer-managed KMS keys.
