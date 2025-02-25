variable "cluster_name" {
}

variable "k8s_host" {
}

variable "k8s_cluster_ca_certificate" {
}

variable "k8s_client_token" {
}

variable "password" {
  default = ""
}

variable "applications" {
}

variable "service_type" {
  default = "ClusterIP"
}
