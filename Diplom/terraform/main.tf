terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

#Provider
provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
}


#Network
resource "yandex_vpc_network" "network1" {
  name = "network1"
}
# Создание подсетей
resource "yandex_vpc_subnet" "subnet1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network1.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}
resource "yandex_vpc_subnet" "subnet2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network1.id
  v4_cidr_blocks = ["192.168.2.0/24"]
}
resource "yandex_vpc_subnet" "subnet-gw" {
  name           = "subnet-gw"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.3.0/24"]
  network_id     = yandex_vpc_network.network1.id
}



#WebServers
#webserver1
resource "yandex_compute_instance" "webserver1" {
  name        = "webserver1"
  platform_id = "standard-v3"
  zone     = "ru-central1-a"
  hostname = "webserver1"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8pnse1rshdvced0u8h"
      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#webserver2
resource "yandex_compute_instance" "webserver2" {
  name        = "webserver2"
  platform_id = "standard-v3"
  zone     = "ru-central1-b"
  hostname = "webserver2"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8pnse1rshdvced0u8h"
      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet2.id
    nat       = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#zabbix
resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  platform_id = "standard-v3"
  zone     = "ru-central1-a"
  hostname = "zabbix"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8pnse1rshdvced0u8h"
      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}


#elastic
resource "yandex_compute_instance" "elast" {
  name        = "elast"
  platform_id = "standard-v3"
  zone     = "ru-central1-a"
  hostname = "elast"
  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8pnse1rshdvced0u8h"
      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#kibana
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  platform_id = "standard-v3"
  zone     = "ru-central1-a"
  hostname = "kibana"
  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = "fd8pnse1rshdvced0u8h"
      size     = 10
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat       = true
  }
  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#gateway

resource "yandex_compute_instance" "gateway" {

  name        = "gateway"
  zone        = "ru-central1-b"
  platform_id = "standard-v3"
  hostname    = "gateway"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8pnse1rshdvced0u8h"
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-gw.id
    dns_record {
      fqdn = "ssgw.srv."
      ttl  = 300
    }
    nat                = true
    security_group_ids = [yandex_vpc_security_group.sg-gw.id]
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

#alb-address

resource "yandex_vpc_address" "addr1" {
  name = "addr-1"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

#target-group

resource "yandex_alb_target_group" "tg1" {
  name = "tg1"

  target {
    subnet_id  = yandex_compute_instance.webserver1.network_interface.0.subnet_id
    ip_address = yandex_compute_instance.webserver1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_compute_instance.webserver2.network_interface.0.subnet_id
    ip_address = yandex_compute_instance.webserver2.network_interface.0.ip_address
  }
}

#backend-group

resource "yandex_alb_backend_group" "bg1" {
  name = "bg1"

  http_backend {
    name             = "backend1"
    weight           = 1
    port             = 80
    target_group_ids = ["${yandex_alb_target_group.tg1.id}"]

    load_balancing_config {
      panic_threshold = 9
    }
    healthcheck {
      timeout             = "5s"
      interval            = "2s"
      healthy_threshold   = 2
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

#router

resource "yandex_alb_http_router" "router1" {
  name = "router1"
}

#virtual-host

resource "yandex_alb_virtual_host" "vh1" {
  name           = "vh1"
  http_router_id = yandex_alb_http_router.router1.id

  route {
    name = "route1"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.bg1.id
        timeout          = "3s"
      }
    }
  }
}

#load-balancer

resource "yandex_alb_load_balancer" "alb1" {
  name               = "alb1"
  network_id         = yandex_vpc_network.network1.id
  security_group_ids = [yandex_vpc_security_group.sg-balancer.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet1.id
    }

    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet2.id
    }
  }

  listener {
    name = "listener1"
    endpoint {
      address {
        external_ipv4_address {
          address = yandex_vpc_address.addr1.external_ipv4_address[0].address
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.router1.id
      }
    }
  }
}

#sg-balancer

resource "yandex_vpc_security_group" "sg-balancer" {
  name       = "sg-balancer"
  network_id = yandex_vpc_network.network1.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "healthchecks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }
}

#sg-private

resource "yandex_vpc_security_group" "sg-private" {
  name       = "sg-private"
  network_id = yandex_vpc_network.network1.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "balancer"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "elasticsearch"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9200
  }

  ingress {
    protocol          = "ANY"
    description       = "any"
    security_group_id = yandex_vpc_security_group.sg-gw.id
  }

  ingress {
    protocol       = "TCP"
    description    = "filebeat"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5044
  }

  ingress {
    protocol       = "TCP"
    description    = "filebeat"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5043
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix-agent"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix-agent"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10051
  }


}

#sg-public

resource "yandex_vpc_security_group" "sg-public" {
  name       = "sg-public"
  network_id = yandex_vpc_network.network1.id


  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }


  ingress {
    protocol       = "TCP"
    description    = "zabbix"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix-agent"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 10051
  }

  ingress {
    protocol       = "TCP"
    description    = "kibana"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol          = "ANY"
    description       = "any"
    security_group_id = yandex_vpc_security_group.sg-gw.id
  }

}

#sg-gateway

resource "yandex_vpc_security_group" "sg-gw" {
  name       = "sg-gw"
  network_id = yandex_vpc_network.network1.id


  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
}

resource "yandex_compute_snapshot_schedule" "default-1" {
  name = "default-1"

  schedule_policy {
    expression = "0 5 ? * *"
  }

  snapshot_count = 7

  snapshot_spec {
    description = "daily"
  }

  disk_ids = [yandex_compute_instance.webserver1.boot_disk[0].disk_id,
    yandex_compute_instance.webserver2.boot_disk[0].disk_id,
    yandex_compute_instance.zabbix.boot_disk[0].disk_id,
    yandex_compute_instance.elast.boot_disk[0].disk_id,
    yandex_compute_instance.kibana.boot_disk[0].disk_id,
  yandex_compute_instance.gateway.boot_disk[0].disk_id]
}
