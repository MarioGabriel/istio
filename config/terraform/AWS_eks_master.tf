// AWS IAM role for EKS Master
resource "aws_iam_role" "master" {
  name = "terraform-eks-master"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

// Attaches role to EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "poc-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.master.name}"
}

// Attaches role to EKS Service Policy
resource "aws_iam_role_policy_attachment" "poc-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.master.name}"
}



// EKS Master Cluster IAM Role
resource "aws_security_group" "eks" {
  name        = "terraform-eks-master"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.demo.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Allows traffic from my IP to the EKS API
resource "aws_security_group_rule" "poc-ingress-workstation-https" {
  cidr_blocks       = ["37.58.174.21/32"] # My IP
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks.id}"
  to_port           = 443
  type              = "ingress"
}



//  Creates the EKS Cluster
resource "aws_eks_cluster" "demo" {
  name            = "terraform-eks-master"
  role_arn        = "${aws_iam_role.master.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.eks.id}"]
    subnet_ids         = ["${aws_subnet.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.poc-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.poc-AmazonEKSServicePolicy",
  ]
}


// Creates local kubeconfig file
locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.demo.endpoint}
    certificate-authority-data: ${aws_eks_cluster.demo.certificate_authority.0.data}
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
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster-name}"
KUBECONFIG
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}