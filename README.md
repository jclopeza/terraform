# Terraform

[Terraform](https://www.terraform.io) es multicloud y con múltiples providers.

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
Con este comando generamos y mostramos el plan de ejecución. Nos indica qué pasaría si aplicásemos las templates de terraform existentes. Mostrará algo como ...
```
Terraform will perform the following actions:

  # aws_instance.web will be created
  + resource "aws_instance" "web" {
      + ami                          = "ami-026c8acd92718196b"
      + arn                          = (known after apply)
      + associate_public_ip_address  = (known after apply)
  ...
```
Veremos los recursos que se crearán. Algunos de los datos que se muestran los habremos dado nosotros y el resto de datos serán `compute`, es decir, generados por Amazon una vez que se han creado los recursos como los IDs, etc.
#### --target
En el caso de que se vayan a crear más de un recurso, podemos afinar poniendo `--target`. Por ejemplo, si después de ejecutar `terraform plan` obtenemos lo siguiente ...
```
  ...
  # aws_security_group.allow_ssh_anywhere will be created
  + resource "aws_security_group" "allow_ssh_anywhere" {
      + arn                    = (known after apply)
      + description            = "Allow all inbound traffic to ssh"
      + egress                 = [
  ...
```
Podemos ejecutar
```
terraform plan --target aws_security_group.allow_ssh_anywhere
```
Y sólo se generará el plan para el recurso seleccionado.
### apply
Con este comando aplicamos los cambios en Amazon. Nos mostraría de nuevo el plan de ejecución diciendo qué pasaría (recursos nuevos, modificados, recursos a eliminar, etc.). Pide confirmación, escribimos `yes` y se creará la nueva instancia EC2 en AWS.

Pero no podremos conectarnos con ella porque no tenemos un **security group** asociado.

Aquí también podemos pasar como parámetro `--target` visto en la sección anterior.

#### Creación de security group a mano en AWS
Creamos a mano un security group para poder acceder a la instancia que hemos creado. Creamos una `inbound rule` que permita acceso al puerto 22 vía SSH desde cualquier origen. La denominamos `ssh-anywhere` y tiene el ID `sg-0fc3bb2ae405d6f19`.

En la documentación encontramos que uno de los argumentos del recurso `aws_instance` es `vpc_security_group_ids` (es un array). Modificamos nuestro fichero `instance.tf` y quedará así:
```
resource "aws_instance" "web" {
  ami           = "ami-026c8acd92718196b"
  instance_type = "t3.micro"
  vpc_security_group_ids = ["sg-0fc3bb2ae405d6f19"]
  tags = {
    Name = "test-terraform"
  }
}
```
Si ejecutamos de nuevo `terraform plan` veremos que se modificará un recurso. Si ejecutamos `terraform apply` tendremos la instancia con el nuevo **security group** asociado.

Ya podremos conectarnos pero no podremos hacer login porque no tenemos un **key-pair** asociado. Ahora, no podemos asociar un key-pair a una instancia que ya está corriendo. Hay que crear una nueva, siempre. El siguiente paso será modificar el fichero `instance.tf` y agregar la línea **key_name**.
```
resource "aws_instance" "web" {
  ami           = "ami-026c8acd92718196b"
  instance_type = "t3.micro"
  key_name = "jcla"
  vpc_security_group_ids = ["sg-0fc3bb2ae405d6f19"]

  tags = {
    Name = "test-terraform"
  }
}
```
Si hacemos `terraform plan` veremos que se va a destruir una instancia y crear una nueva. El motivo es el comentado antes, no se puede asociar un **key-pair** en una instancia ya creada.

### destroy
Nos permitirá destruir infraestructura. Para ver el plan de ejecución para destruir recursos ejecutaríamos ...
```
terraform plan --destroy
```
Para eliminar todos los recursos definidos, ejecutaríamos ...
```
terraform destroy
```

## Creación de recursos necesarios desde Terraform
Antes tuvimos que crear a mano los recursos necesarios para nuestra instancia como el **security group** o el **key pair**. Ahora veremos cómo crear esos recursos directamente desde Terraform.

### Creación de un nuevo security group
Creamos un nuevo fichero `sg.tf` (sg = security group)
```
resource "aws_security_group" "allow_ssh_anywhere" {
  name        = "allow_ssh_anywhere"
  description = "Allow all inbound traffic to ssh"
  vpc_id      = "vpc-983f84e1"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
```
Una de las cosas que hemos hecho ha sido dar el ID de la VPC de forma manual. Cuando creamos un SG de forma manual, en la consola nos pregunta para qué VPC es ese SG. Entro en la consola y veo que tengo sólo una VPC y que su id es `vpc-983f84e1`.

### Asignación del security group creado a la nueva instancia
Cuando definíamos la instancia, teníamos algo como:
```
vpc_security_group_ids = ["sg-019ba326777f78068"]
```
Pero ahora el SG lo vamos a crear de forma dinámica y en principio no sabemos su ID. ¿Qué hacer?, pues **referenciarlo**.

Para eso, tenemos que quedarnos con el nombre del SG, en este caso es `aws_security_group.allow_ssh_anywhere` y lo referenciamos en el atributo `vpc_security_group_ids` de la siguiente forma:
```
vpc_security_group_ids = ["${aws_security_group.allow_ssh_anywhere.id}"]
```
Tenemos que darnos cuenta que aquí hemos utilizado el **atributo** `id`. Estos atributos están en la documentación de los SG (y de cualquier otro recurso).

### Creación de un nuevo key_pair
Se trataría de crear un nuevo fichero `keypair.tf` con el siguiente contenido:
```
resource "aws_key_pair" "jcla_dell" {
  key_name   = "terraform-test-keypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAA..."
}
```
Y para que esta clave sea utilizada por nuestra instancia, se trataría de incluir la siguiente línea en el fichero `instance.tf`
```
key_name = "${aws_key_pair.jcla_dell.key_name}"
```
## Outputs, cómo obtener información de los recursos creados por Terraform
Por ejemplo, vamos a extraer la publi_ip de la instancia que estamos creando. Creamos un fichero `outputs.tf` con el contenido
```
output "instance_public_ip" {
  value = "${aws_instance.web.public_ip}"
}
```
Con el comando
```
terraform output
```
obtendríamos el resultado de la public_ip.
```
instance_public_ip = 52.54.138.95
```
El nombre de la variable de salida es aleatorio, podemos utilizar el que queramos.

## Creación de una Elastic IP
Creamos un fichero de nombre `eip.tf` con el siguiente contenido.
```
resource "aws_eip" "web_eip" {
  instance = "${aws_instance.web.id}"
}
```
Ya no me interesa el valor *aws_instance.web.public_ip* que definimos en el fichero `outputs.ts` porque esa ip pública se sustituirá por la elastic IP. Por tanto modificamos el fichero `outputs.tf` con el siguiente contenido:
```
output "instance_public_ip" {
  value = "${aws_eip.web_eip.public_ip}"
}
output "instance_public_dns" {
  value = "${aws_eip.web_eip.public_dns}"
}
```
Ahora también mostramos el DNS público además de la IP pública.

## Variables

### Definición de variables
Creamos el fichero `variables.tf` con el siguiente contenido:
```
variable "project_name" {
  type = "string"
}
```
Si ahora ejecutamos `terraform plan` nos preguntará por el valor de la variable porque no la hemos definido.

También podemos evitar poner el tipo de variable de la siguiente forma:
```
variable "project_name" {}
```


### Utilización de variables
Por ejemplo, vamos al fichero `sg.tf` y decidimos que el nombre del SG fuera:
```
name        = "${var.project_name}-allow_ssh_anywhere"
```
Es muy útil cuando estamos reutilizando código. Hacemos lo mismo en el tag de la instancia.

### Fijación de variables
Creamos un fichero de nombre `terraform.tfvars` con el contenido:
```
project_name = "Calculadora"
```

### Llevamos el VPC id, el AMI id y el tipo de instancia a nuestras variables
El fichero `variables.tf` quedaría:
```
variable "project_name" {}
variable "vpc_id" {}
variable "ami_id" {}
variable "instance_type" {}
```
Y el fichero `terraform.tfvars` así:
```
project_name = "Calculadora"
vpc_id = "vpc-983f84e1"
ami_id = "ami-026c8acd92718196b"
instance_type = "t3.micro"
```

## Creación de *user data*
Con esto podremos provisionar nuestra máquina creada en cloud. Creamos un fichero de nombre `user-data.txt` con el siguiente contenido.
```
#!/bin/bash
sudo apt-get update -y
sudo apt-get install apache2 -y
echo "hola mundo" | sudo tee /var/www/html/index.html
```
Ahora tenemos que incluir este fichero en el *user data*. Modificamos el fichero `instance.tf` que quedaría de la siguiente forma (con el nuevo campo **user_data**):
```
resource "aws_instance" "web" {
  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.jcla_dell.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow_ssh_anywhere.id}"]
  user_data = "${file("user-data.txt")}"
  tags = {
    Name = "${var.project_name}-instance"
  }
}
```
Hemos instalado apache, ahora tendríamos que:
1. modificar el SG para permitir acceso al puerto 80.
2. modificar la instancia para asociarle el nuevo SG que hemos creado.

Nuestro fichero `sg.tf` quedaría así:
```
resource "aws_security_group" "allow_ssh_anywhere" {
  name        = "${var.project_name}-allow_ssh_anywhere"
  description = "Allow all inbound traffic to ssh"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_http_anywhere" {
  name        = "${var.project_name}-allow_http_anywhere"
  description = "Allow all inbound traffic to http"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
```
Y el fichero `instance.tf` quedaría así:
```
resource "aws_instance" "web" {
  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.jcla_dell.key_name}"
  vpc_security_group_ids = [
      "${aws_security_group.allow_ssh_anywhere.id}",
      "${aws_security_group.allow_http_anywhere.id}"
    ]
  user_data = "${file("user-data.txt")}"
  tags = {
    Name = "${var.project_name}-instance"
  }
}
```

## Simplificando la configuración con los DataSources
Los DataSources nos permiten acceder a recursos de AWS que ya estén creados previamente, o a recursos que no dependen de nosotros como las AMIs, etc. Por ejemplo, vamos a obtener el AMI a utilizar por nuestra instancia EC2 utilizando DataSources.

Creamos un nuevo fichero de nombre `data.tf` con el siguiente contenido que lo que haría sería consultar las AMIs de AWS (le vamos a llamar *ubuntu* a ésta) y va a aplicar una serie de filtros.
```
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
```
Por tanto ya no necesitaríamos el valor `ami_id = "ami-026c8acd92718196b"` que definimos en el fichero `terraform.tfvars` ni la variable `variable "ami_id" {}` que definimos en `variables.tf`. Y en el fichero `instance.tf` tendríamos que cambiar
```
ami           = "${var.ami_id}"
```
por
```
ami           = "${data.aws_ami.ubuntu.image_id}"
```
El campo `image_id` es uno de los atributos del *datasource* aws_ami.

Vamos a hacer lo mismo para eliminar la variable vpc_id de nuestros ficheros `variables.tf` y `terraform.tfvars`. Para ello creamos un nuevo datasource en el mismo fichero `data.tf` con el siguiente contenido.
```
data "aws_vpc" "selected" {
  default = true
}
```
Si vemos la documentación, en los argumentos nos permite indicar si queremos la VPC por defecto. Para utilizar este nuevo datasource, tendríamos que actualizar el fichero `sg.tf` y cambiar:
```
  vpc_id      = "${var.vpc_id}"
```
por
```
  vpc_id      = "${data.aws_vpc.selected.id}"
```

## Launch configurations y autoscaling groups
Creamos un nuevo