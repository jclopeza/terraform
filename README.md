# Terraform

Terraform es multicloud y con múltiples providers.

## Instalación de terraform
Es un simple binario `terraform` que ubicamos en ```/usr/local/bin```.

## Creación de usuario
Creación de usuario `terraform` bajo IAM->Users con permisos de administrador. Sólo damos acceso programático. Con esto conseguimos el access key y el secret key.

## Configuración del provider
Con los datos de acceso podemos configurar el provider. Creación del fichero `provider.tf` con el siguiente contenido:

```
provider "aws" {
  region     = "us-east-1"
  access_key = "**************************"
  secret_key = "**********************************"
}
```

Se puede crear todo en el mismo fichero pero es una **buena práctica** crear diferentes ficheros para diferentes objetivos. Ficheros de provider, ficheros de instancias, ficheros de autoscaling, de elastic ip, etc.

## Configuración de la instancia EC2
Creación del fichero `instance.tf` con el siguiente contenido:

```
resource "aws_instance" "web" {
  ami           = "ami-026c8acd92718196b"
  instance_type = "t3.micro"

  tags = {
    Name = "test-terraform"
  }
}
```

## Comandos básicos

### init
Se bajará una serie de ficheros y plugins que son necesarios para desplegar la infraestructura que hemos definido. Debe ejecutarse en el directorio en el que se encuentra el `provider.tf`. El resultado será algo como ...

```
Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "aws" (terraform-providers/aws) 2.20.0...

...

Terraform has been successfully initialized!

...
```

Como resultado se creará una carpeta de nombre `.terraform` con el siguiente contenido:

```
.terraform/
└── plugins
    └── linux_amd64
        ├── lock.json
        └── terraform-provider-aws_v2.20.0_x4
```

El fichero `terraform-provider-aws_v2.20.0_x4` es un binario para interactuar con AWS.

### plan
Con este comando generamos y mostramos el plan de ejecución. Nos indica qué pasaría si aplicásemos las templates de terraform existentes.


**Data sources:** son todos los elementos de los que podemos extraer información.

Instrucciones sobre cómo generar los ficheros yaml para **Applications**, **Environments** e **Infrastructure**: [https://docs.xebialabs.com/xl-platform/concept/getting-started-with-devops-as-code.html](https://docs.xebialabs.com/xl-platform/concept/getting-started-with-devops-as-code.html).

Instrucciones para gestión de **repositorios blueprints**: [https://docs.xebialabs.com/xl-platform/concept/blueprint_repository.html](https://docs.xebialabs.com/xl-platform/concept/blueprint_repository.html).

Instrucciones para los distintos tipos que se pueden utilizar: [https://docs.xebialabs.com/xl-platform/concept/blueprint-yaml-format.html](https://docs.xebialabs.com/xl-platform/concept/blueprint-yaml-format.html).

Ejemplos reales: [https://github.com/xebialabs/blueprints/blob/master/aws/microservice-ecommerce/blueprint.yaml](https://github.com/xebialabs/blueprints/blob/master/aws/microservice-ecommerce/blueprint.yaml).

## Configuración de repositorios con blueprints

En el fichero `~/.xebialabs/config.yaml` deberá existir una entrada por cada repositorio de blueprints que utilicemos. En el siguiente ejemplo se muestra cómo configurar dos repositorios, uno de tipo Github y otro de tipo http. El repositorio activo se indica en el atributo **current-repository**:

```
blueprint:
  current-repository: LyhSoft Blueprints
  repositories:
  - name: XL Blueprints
    type: http
    url: https://dist.xebialabs.com/public/blueprints/
  - name: LyhSoft Blueprints
    type: github
    repo-name: blueprints
    owner: jclopeza
```

La estructura que debe tener el reposotorio es:
```
blueprints
├── index.json
└── java/
      └── war/
            ├── blueprint.yaml
            ├── xebialabs.yaml
            ├── files/
            │     ├── template1.yaml.tmpl
            │     └── template2.yaml
            │
            └── xebialabs/
                  ├── xld-environment.yaml.tmpl
                  ├── xld-infrastructure.yaml.tmpl
                  ├── xlr-pipeline.yaml.tmpl
                  └── README.md.tmpl
```

