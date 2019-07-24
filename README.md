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