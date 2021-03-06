# Caronaê - Infra

**Infraestrutura do Caronaê na AWS como código**

Infraestrutura do Caronaê na AWS utilizando [Terraform](https://www.terraform.io/) e [Ansible](https://www.ansible.com/).


## Instalação

Instale o [AWS CLI](https://aws.amazon.com/cli) e configure suas credenciais da AWS:

```shell
brew install awscli
aws configure
```

Instale o Terraform e o Ansible e inicialize os plugins:

```shell
brew install terraform ansible
terraform init
```


## Aplicando configuração

Verifique as mudanças a serem aplicadas e se não há erros:

```shell
terraform plan
```

Aplique as mudanças:

```shell
terraform apply
```
