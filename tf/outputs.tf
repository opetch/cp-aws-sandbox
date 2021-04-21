locals {
  hosts = {
    all             = {
      vars = {
        ansible_connection           = "ssh"
        ansible_user                 = "centos"
        ansible_become               = "true"
        ansible_ssh_private_key_file = abspath(local.tmp_private_key_file)
      }
    }
    zookeeper       = {
      hosts = {
        "${lookup(element(aws_instance.hosts, 0), "public_dns")}" = {}
        "${lookup(element(aws_instance.hosts, 1), "public_dns")}" = {}
        "${lookup(element(aws_instance.hosts, 2), "public_dns")}" = {}
      }
    }
    kafka_broker    = {
      hosts = {
        "${lookup(element(aws_instance.hosts, 3), "public_dns")}" = {}
        "${lookup(element(aws_instance.hosts, 4), "public_dns")}" = {}
        "${lookup(element(aws_instance.hosts, 5), "public_dns")}" = {}
      }
    }
    schema_registry = {
      hosts = {
        "${lookup(element(aws_instance.hosts, 6), "public_dns")}" = {}
      }
    }
    kafka_rest      = {
      hosts = {
        "${lookup(element(aws_instance.hosts, 7), "public_dns")}" = {}
      }
    }
    ksql            = {
      hosts = {
        "${lookup(element(aws_instance.hosts, 8), "public_dns")}" = {}
        "${lookup(element(aws_instance.hosts, 9), "public_dns")}" = {}
      }
    }
    kafka_connect   = {
      hosts = {
        "${lookup(element(aws_instance.hosts, 10), "public_dns")}" = {}
      }
    }
    control_center  = {
      hosts = {
        "${lookup(element(aws_instance.hosts, 11), "public_dns")}" = {}
      }
    }
  }
}

output "hosts" {
  # regex to remove quotes around yaml elements
  value = replace(yamlencode(local.hosts), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
}

output "dns" {
  value = aws_instance.hosts.0.public_dns
}
