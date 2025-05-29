terraform {            //Bloque principal de configuracion
  required_providers { //proveedores como AWS o docker
    docker = {
      source  = "kreuzwerker/docker" //proveedor de docker, el aleman
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {}    // se le dice a terraform que use docker para el backend

resource "docker_network" "springboot_net" {
  name = "springboot_network"
}

resource "docker_image" "mysql_image" {
  name = "mysql:8.0"
}

resource "docker_container" "mysql" {              // creaacion del contenedor
  name  = "mysql_db"
  image = docker_image.mysql_image.latest
  networks_advanced {
    name = docker_network.springboot_net.name
  }

  env = [
    "MYSQL_ROOT_PASSWORD=root",
    "MYSQL_DATABASE=mydb",
    "MYSQL_USER=user",
    "MYSQL_PASSWORD=pass"
  ]

  ports {
    internal = 3306
    external = 3306
  }
}                                                  // creacion del contenedor

resource "docker_image" "spring_image" {
  name = "springboot-demo:latest"
  build {
    context    = "${path.module}/app"
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "spring_app" {           //contenedor springboot
  name       = "spring_app"
  image      = docker_image.spring_image.latest
  depends_on = [docker_container.mysql]

  networks_advanced {
    name = docker_network.springboot_net.name
  }

  ports {
    internal = 8080
    external = 8080
  }

  env = [
    "SPRING_DATASOURCE_URL=jdbc:mysql://mysql_db:3306/mydb",
    "SPRING_DATASOURCE_USERNAME=user",
    "SPRING_DATASOURCE_PASSWORD=pass"
  ]
}                                                //contenedor springboot
