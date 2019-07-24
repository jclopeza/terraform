# Terraform

Definiciones de blueprints para el cliente `xl`.

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
