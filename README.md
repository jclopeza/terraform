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

### validate
Para validar que los ficheros están bien construídos.

### fmt
Para formatear los ficheros (espacios, identación, ...). Suele utilizarse antes de subirse a git.

### graph
Para creación de gráficos:
```
terraform graph | dot -Tsvg > /tmp/graph.svg
```

### import
Permite que recursos que estén creados a mano puedan ser importados por terraform. Para pequeñas cosas.

### refresh
Actualiza el estado `terraform.tfsate` con el código de los ficheros tf.

### show
Veremos todos los atributos disponibles de los recursos. Es una forma fácil de ver los atributos que tenemos disponibles para los outputs.

### workspace
Se trata de poder tener el mismo código pero con distintos estados.

Para crear un nuevo workspace
```
terraform workspace new testing
```
Esto creará el directorio `terraform.tfstate.d/testing`

Para listar los workspaces disponibles
```
terraform workspace list
```

Para seleccionar un workspace distinto
```
terraform workspace select testing
```

Es posible acceder al workspace desde las templates tf de la siguiente forma, por ejemplo:
```
project_name = "${var.project_name}-${terraform.workspace}"
```

Probablemente querramos utilizar distintas variables para los distintos entornos/workspaces. Se puede hacer de la siguiente forma:
```
instance_type = "${terraform.workspace == "production" ? "t2.large": "t2.micro"}"
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
Movemos todo el contenido al directorio `instancia_web` y duplicamos todo a una nueva carpeta `instancias_web_con_asg_y_elb`. Vamos a modificar el código para poder implementar un *launch configuration* y un *autoscaling group*. Esto no va a permitir que el *autoscaling group* lance una serie de instancias (que las definimos en el *launch configuration*).

### Creación del launch configuration
1. Eliminamos el fichero `instance.tf`, no lo necesitamos.
2. Eliminamos el fichero `eip.tf`, no lo necesitamos.
3. Eliminamos el fichero `outputs.tf`, no lo necesitamos.
4. Creamos el nuevo fichero `lc.tf` con el siguiente contenido.
```
resource "aws_launch_configuration" "web" {
  name_prefix          = "${var.project_name}-lc_" // Más versátil que name
  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${aws_key_pair.jcla_dell.key_name}"
  security_groups = [
    "${aws_security_group.allow_ssh_anywhere.id}",
    "${aws_security_group.allow_http_anywhere.id}"
    ]
  user_data = "${file("user-data.txt")}"
  // Aquí no necesitamos los tags ya que se indican directamente en el autoscaling group
}
```
### Creación del autoscaling group
Creamos el fichero `asg.tf` con el siguiente contenido:
```
resource "aws_autoscaling_group" "web" {
  name                      = "${var.project_name}-web"
  max_size                  = 2
  min_size                  = 0
  desired_capacity          = 0
  launch_configuration      = "${aws_launch_configuration.web.name}"
  // Aqui indicamos la subnet. Las ponemos fijas pero luego utilizaremos un datasource
  vpc_zone_identifier       = ["subnet-064ff72a", "subnet-0caf2300", "subnet-4b69d911"]
  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true // Con esto indicamos que el tag se ponga también en las instancias que se crean
  }
}
```
Esto no creará ninguna instancia porque `desired_capacity = 0`, pero aunque pongamos que queremos 2 instancias, no servirá de nada porque:
* las ip's son dinámicas
* las dos instancias están separadas

Necesitamos por tanto un **balanceador de carga** con una IP fija y que las instancias se auto-registren en ese balanceador a medida que se crean y que se eliminen del balanceador a medida que se destruyan.

### Creación del balanceador de carga
Primero modificamos el `user-data.txt` para incluir el id de la instancia EC2 en el index.html. Para ello incluímos la siguiente línea (con este endpoint tenemos acceso a muchos meta-datos de la instancia):
```
instance_id=$(curl -s 169.254.169.254/latest/meta-data/instance-id)
```
Y tendremos el `user-data.txt` como sigue:
```
#!/bin/bash
sudo apt-get update -y
sudo apt-get install apache2 -y
instance_id=$(curl -s 169.254.169.254/latest/meta-data/instance-id)
echo "Nombre de la instancia EC2 = $instance_id" | sudo tee /var/www/html/index.html
```
Ahora si intentamos aplicar los cambios, tendrá que eliminar y crear un *launch configuration*. Esto nos dará error porque ya está asociado a un *autoscaling group*. Esto lo solucionamos incluyendo las líneas
```
  lifecycle {
      create_before_destroy = true
  }
```
en el fichero `lc.tf`. Esto creará el nuevo *launch configuration*, lo asociará al *autoscaling group* y finalmente se borrará el antiguo *launch configuration*.

Ahora configuramos propiamente el **load balancer**. Creamos el fichero `elb.tf` con el siguiente contenido.
```
resource "aws_elb" "web" {
  name                = "${var.project_name}-elb-web"
  subnets             = ["subnet-064ff72a", "subnet-0caf2300", "subnet-4b69d911"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 2
    target              = "HTTP:80/"
    interval            = 10
  }

  tags = {
    Name = "${var.project_name}-elb-web"
  }
}
```
Pero aún no está listo. Aún falta configurar el *security group* que va a utilizar este ELB como el attach de las instancias a través del *autoscaling group*. Podemos utilizar el mismo que definimos antes, por tanto bastaría añadir la siguiente línea al fichero `elb.tf`:
```
security_groups = ["${aws_security_group.allow_http_anywhere.id}"] //No aplicamos el SG ssh
```
Sólo nos queda asociar las instancias al ELB. Editamos el fichero `asg.tf` e inluímos la línea *load_balancers* como sigue:
```
load_balancers            = ["${aws_elb.web.name}"]
```

### Health checks para los autoscaling groups
El tipo de chequeo que hace el *autoscaling group* es te dipo EC2. Verifica que la instancia está arriba y que se llega a ella. Puede que apache esté caído y eso no es ningún problema para el *autoscaling group*. Lo que queremos hacer es que el *autoscaling group* haga los mismos chequeos que el ELB. Si apache está caído, que el *autoscaling group* cree una nueva instancia y de por finalizada la otra.

Para ello, modificamos el fichero `asg.tf` e incluímos la siguiente línea:
```
health_check_type         = "ELB"
```
A partir de ahora, el *autoscaling group* se apoyará en los chequeos del balanceador de carga para determinar si crea o no una nueva instancia EC2.

## DataSources
Vamos a mejorar el ejemplo anterior y vamos a obtener las subredes o subnets con datasources. Para eso modificamos el fichero `data.tf` e incluimos nuevas líneas para que se recuperen **todas las subnets** asociadas a una determinada VPC.
```
data "aws_subnet_ids" "selected" {
  vpc_id = "${data.aws_vpc.selected.id}"
}
```
Ya podemos modificar el fichero `elb.tf` y sustituir la línea
```
subnets             = ["subnet-064ff72a", "subnet-0caf2300", "subnet-4b69d911"]
```
por esta otra
```
subnets             = "${data.aws_subnet_ids.selected.ids}"
```
Y hacer también la sustitución en el fichero `asg.tf` y sustituir la línea
```
vpc_zone_identifier       = ["subnet-064ff72a", "subnet-0caf2300", "subnet-4b69d911"]
```
por esta otra
```
vpc_zone_identifier       = "${data.aws_subnet_ids.selected.ids}"
```

## Terraform console
Con `terreform console` tenemos acceso a una consola en la que podemos ver el valor de variables, debugear, etc. Ejemplo:
```
> var.project_name
calculadora
> data.aws_subnet_ids.selected.ids
[
  "subnet-064ff72a",
  "subnet-0caf2300",
  "subnet-4b69d911",
  "subnet-691e2c55",
  "subnet-a7a8bfc2",
  "subnet-fbcbbab3",
]
>
```

## Interpolation syntax
Documentado aquí: https://www.terraform.io/docs/configuration-0-11/interpolation.html

Echar un vistazo a las *built-in functions*. Podemos buscar contenido en listas, etc. Luego podrá usarse con los condicionales.

## Templates
Terraform tiene embebido un motor de templates. Será muy útil cuando creemos módulos. Veamos cómo funcionan. Primero creamos el fichero `template.tf` con el siguiente contenido.
```
data "template_file" "user-data" {
  template = "${file("template.tpl")}"
  vars = {
    test_var = "test_value"
  }
}
```
Ahora creamos el fichero `template.tpl` con:
```
Hola mundo esto es una prueba
```
Si hacemos `terraform plan` fallará porque es necesario descargar el plugin para las templates. Se soluciona con `terraform init`. Vamos a usar este template para generar la salida. Creamos por tanto el fichero `output.tf` con el siguiente contenido:
```
output "template_rendered" {
    value = "${data.template_file.user-data.rendered}"
}
```
Con esto tendremos como salida el contenido de la template renderizada. Ahora, ¿cómo accedemos al valor de nuestras variables desde la template? Muy fácil, basta referenciarlas de la siguiente forma:
```
variable test_var = ${test_var}
```
No es necesario utilizar `var.name` como hacíamos antes. Se puede acceder de forma directa si hemos definido las variables dentro del `template_file`.

### Pasar a las templates variables que existen en el sistema
Y si queremos pasar el `project_name` a la template?. Muy fácil, tendríamos que modificar el fichero template.tf que quedaría del siguiente modo:
```
data "template_file" "user-data" {
  template = "${file("template.tpl")}"
  vars = {
    test_var = "test_value"
    project_name = "${var.project_name}"
  }
}
```
De esta forma tendríamos disponible la variable `project_name` lista para poder utilizar en nuestros templates. Esto se verá en detalle con los módulos.

### User data como template
Modificamos el fichero template.tf, eliminamos las variables y tomamos como template el user-data.txt. Quedaría así:
```
data "template_file" "user-data" {
  template = "${file("user-data.txt")}"
  vars = {
  }
}
```
El siguiente paso sería usar la template renderizada en el *launch configuration*. Para ello modificamos el fichero `lc.tf` y en el campo `user_data` indicamos que utilice la template en lugar del fichero `user-data.txt`. Cambiaríamos la línea
```
user_data = "${file("user-data.txt")}"
```
por
```
user_data = "${data.template_file.user-data.rendered}"
```
Eliminamos ahora los ficheros template.tpl y output.tf, no los vamos a necesitar más.

Vamos a pasar al `user-data.txt` el *project_name* como variable. El fichero template.tf quedaría así:
```
data "template_file" "user-data" {
  template = "${file("user-data.txt")}"
  vars = {
      project_name = "${var.project_name}"
  }
}
```
Y en el `user-data.txt` hacemos uso de esa variable:
```
#!/bin/bash

# Este es el user data para el proyecto ${project_name}
sudo apt-get update -y
sudo apt-get install apache2 -y
instance_id=$(curl -s 169.254.169.254/latest/meta-data/instance-id)
echo "Nombre de la instancia EC2 = $instance_id" | sudo tee /var/www/html/index.html
```

## Ficheros de estado
¿Cómo sabe Terraform el estado en que se encuentran los recursos en Amazon?, ¿cómo monitoriza los cambios y mantiene el estado?

### terraform.tfstate
Es el fichero de estado de terraform. Tiene estructura json y mantiene un registro de todos los cambios que Terraform ha hecho en la infraestructura. **Es el fichero en el que se va apoyar para comparar el estado actual de la infraestructura con el estado de la infraestructura real en Amazon**.

### Remote state
Es posible almacenar el estado en localizaciones remotas. Por ejemplo, en buckets S3. Para ello, creamos el fichero de nombre `remote_state.tf` con el siguiente contenido:
```
terraform {
  backend "s3" {
    bucket = "vcc-terraform-bucket"
    key = "terraform/states/web_intance.tfstate"
    region = "us-east-1"
  }
}
```
Esto escribirá en un bucket de S3 el estado de Terraform. Es una forma muy buena si se está trabajando en equipo y hay varias personas modificando recursos en Amazon.

En local, dentro del directorio `.terraform` existirá un fichero `terraform.tfstate` pero lo único que contendrá será la referencia al bucket de S3 dondé está el fichero válido.

Pero esto plantea un nuevo problema, y es el que dos usuarios estén modificando a la vez recursos en AWS. Para esto están los **locks**.

### Locks
El locking se hace a través de una tabla que necesitamos crear en DynamoDB. Con esto podremos activar el locking en nuestro Bucket de S3. Tendríamos que:

1. Crear una tabla en DynamoDB en AWS. La tabla tiene que tener un atributo de nombre "LockID".
2. Incluir una nueva línea en el fichero `remote_state.tf` indicando la tabla que hemos creado en DynamoDB:
```
terraform {
  backend "s3" {
    bucket = "vcc-terraform-bucket"
    key = "terraform/states/web_intance.tfstate"
    region = "us-east-1"
    dynamodb_table = "TerraformLock"
  }
}
```

## Acceder a outputs de otros proyectos
Esto será fundamental cuando trabajemos con módulos. Suponemos que tenemos dos proyectos, proyecto1 y proyecto2. Cada uno con su *remote state*.

Dentro de proyecto1 creamos los siguientes ficheros y el siguiente contenido:
* `provider.tf`
```
provider "aws" {
  region     = "us-east-1"
}
```
* `data.tf`
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
* `instance.tf`
```
resource "aws_instance" "web" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  tags = {
    Name = "HelloWorld"
  }
}
```
* `eip.tf`
```
resource "aws_eip" "web" {
  instance = "${aws_instance.web.id}"
}
```
* `remote_state.tf`
```
terraform {
  backend "s3" {
    bucket = "jcla"
    key = "terraform/proyecto1.tfstate"
    region = "us-east-1"
  }
}
```
Luego ejecutamos `terraform init` y `terraform apply`. Ahora creamos un fichero `output.tf` con el siguiente contenido:
```
output "web_public_ip" {
    value = "${aws_eip.web.public_ip}"
}
```

**Ahora, ¿cómo accedemos a esas variables que se definen en el fichero `output.tf` desde otro fichero?**
Dentro de proyecto2 creamos los siguientes ficheros y el siguiente contenido:
* `provider.tf`
```
provider "aws" {
  region     = "us-east-1"
}
```
* `remote_state.tf`
```
terraform {
  backend "s3" {
    bucket = "jcla"
    key = "terraform/proyecto2.tfstate"
    region = "us-east-1"
  }
}
```
Con `terraform init` iniciamos los plugins, el provider, etc. En este proyecto2 podemos crear una instancia con un SG que abra el acceso a la IP que tenemos en el output del otro proyecto. O por ejemplo crear un registro DNS donde apuntáramos a un record concreto a la IP del proyecto1.

Tenemos que acceder al fichero de estado del otro proyecto. Tenemos que utilizar un datasource que nos va a permitir acceder a un remote state. Primero creamos un fichero de nombre `data.tf` donde indicamos dónde se encuentra el fichero de estado remoto.
```
data "terraform_remote_state" "proyecto1" {
  backend = "s3"
  config = {
    bucket = "jcla"
    key    = "terraform/proyecto1.tfstate"
    region = "us-east-1"
  }
}
```
**Esto último nos crearía un datasource y vamos a poder acceder a todos los outputs del proyecto1** de la misma forma que accedemos a cualquier otro datasource.

Para ver la salida, creamos por ejemplo un nuevo fichero de nombre `output.tf` para recoger los datos del estado remoto de otro proyecto.
```
output "web_public_ip_proyecto1" {
    value = "${data.terraform_remote_state.proyecto1.outputs.web_public_ip}"
}
```
Casos de uso. Imaginamos que hay muchos working directories porque los organizamos por aplicación, funcionalidad o lo que sea. Uno para la aplicación de login, otro para la aplicación que permite a los usuarios acceder a tal, ... Y luego queremos centralizar la gestión DNS en un proyecto concreto. Este proyecto podría acceder a todos los outputs de los demás proyectos para obtener las IPs, las de los balanceadores de carga.

## Módulos
Nos van a permitir encapsular varios recursos. El objetivo es la reutilización de código. Como SG, elastic ip, etc ... Imaginamos que tenemos 3 entornos. Serán *working directories* y cada uno tendrá el código necesario para crear el entorno. Si no usásemos módulos, tendríamos que repetir todo el código. Si hay que corregir un error, habría que hacerlo en dos sitios ... **no es mantenible**.

Para crear un módulo primero creamos un directorio, por ejemplo, `ec2-with-eip`. Los ficheros que van dentro de un módulo son iguales, pero la diferencia es que los módulos van a tener **input** y **outputs**. Por ejemplo, vamos a usar un `security group`.

Creamos un fichero sg.tf con el siguiente contenido. **Definimos una serie de variables**.
```
resource "aws_security_group" "allow_all" {
  name        = "${var.sg_name}"
  description = "SG ${var.sg_name}"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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

Ahora creamos un fichero de variables de nombre `inputs.tf` **que van a ser los inputs** con el siguiente contenido:
```
variable "sg_name" {}
variable "vpd_id" {}
```
Cuando invoquemos al módulo, tendremos que pasar unos **inputs** que serán valores para las variables que acabamos de definir. A su vez, este módulo podrá tener **outputs**. Creamos un fichero `outputs.tf` con el siguiente contenido.

### ¿Cómo utilizaríamos este módulo?
Creamos dos directorios, `testing` y `produccion`. Dentro del directorio `testing`, por ejemplo, necesitamos como mímino:
1. Crear un `provider.tf`
2. Un fichero donde invoquemos el módulo de nombre `ec2.tf` con el siguiente contenido.
```
module "ec2" {
    // Lo mínimo que necesitamos es la ruta donde estoy guardando el módulo
    source = "/home/jcla/Projects/desarrollo/Terraform/modulos/ec2-with-eip"
    // Como el módulo tiene inputs, tenemos que incluirlos ahora
    sg_name = "ec2-testing"
    vpc_id = "vpc-983f84e1"
}
```
El siguiente paso sería ejecutar `terraform init`. Además de descargar el provider se descargaría el código asociado al módulo (de estar en un repositorio Git) o crearía un enlace (en caso de estar en local). Esta es la estructura de directorios que quedará tras la ejecución del `init`.
```
.
├── ec2.tf
├── provider.tf
└── .terraform
    ├── modules
    │   ├── ec2 -> /home/jcla/Projects/desarrollo/Terraform/modulos/ec2-with-eip
    │   └── modules.json
    └── plugins
        └── linux_amd64
            ├── lock.json
            └── terraform-provider-aws_v2.21.0_x4
```
Igual podríamos repetirlo para producción.

### ¿Cómo solucionar errores en un módulo?
Por ejemplo, cambiamos la descripción. Volvemos a hacer `terraform apply` y tendremos los cambios aplicados.

### ¿Cómo usar los outputs de los módulos?
Crearíamos un `output.tf` en nuestro proyecto (testing/producción) que hiciera referencia al output del módulo. Quedaría un fichero como el siguiente:
```
output "connection_string" {
    // El valor que vamos a utilizar del módulo está en el outputs del módulo
    value = "ssh ubuntu@${module.ec2.eip}"
}
```
Podremos utilizar varios módulos en un fichero y **podremos utilizar los outputs de un módulo como inputs de otro**. Por ejemplo, un módulo crea una VPC y devuelve el ID como output, y podemos utilizarlo en otro módulo.

### Almacenar nuestros módulos en repositorios Git
Esto, además, nos permitirá trabajar con distintas versiones de nuestros módulos, algo que es muy interesante.

Lo único que tenemos que hacer es cambiar:
```
source = "/home/jcla/Projects/desarrollo/Terraform/modulos/ec2-with-eip"
```
por
```
source = "github.com/jclopeza/terraform-module-ec2-with-eip"
```
En este caso, `terraform init` se va a descargar el código del repositorio Git. Esto implica que la máquina donde se ejecute terraform tiene que tener instalado git.

Ahora veamos cómo hacer un cambio en un módulo alojado en Git. Ojo, si hacemos `terraform init` ya no se descargará el módulo porque ya está descargado. La forma de solucionar esto es mediante los `tags` y `releases` en git. Lo único que tendremos que hacer será cambiar:
```
source = "github.com/jclopeza/terraform-module-ec2-with-eip"
```
por
```
source = "github.com/jclopeza/terraform-module-ec2-with-eip?ref=v1.0.1"
```
