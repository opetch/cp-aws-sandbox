variable instance_type {
  type = string
  default = "t3.large"
  description = "The instance type for the machines to provision"
}
variable instance_count {
  type = number
  default = 3
  description = "The number of instances to provision the Confluent Kafka cluster on"
}
