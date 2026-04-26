data "yandex_vpc_network" "speedtest" {
  network_id = "enpd0e5nkasbvemdhs1a"
}

data "yandex_vpc_subnet" "speedtest" {
  subnet_id = "e2lsu4527ft6oev4q9o0"
}
