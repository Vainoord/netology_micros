# Домашнее задание к занятию «Организация сети»

### Подготовка к выполнению задания

1. Домашнее задание состоит из обязательной части, которую нужно выполнить на провайдере Yandex Cloud, и дополнительной части в AWS (выполняется по желанию). 
2. Все домашние задания в блоке 15 связаны друг с другом и в конце представляют пример законченной инфраструктуры.  
3. Все задания нужно выполнить с помощью Terraform. Результатом выполненного домашнего задания будет код в репозитории. 
4. Перед началом работы настройте доступ к облачным ресурсам из Terraform, используя материалы прошлых лекций и домашнее задание по теме «Облачные провайдеры и синтаксис Terraform». Заранее выберите регион (в случае AWS) и зону.

---
### Задание 1. Yandex Cloud 

**Что нужно сделать**

1. Создать пустую VPC. Выбрать зону.
2. Публичная подсеть.

 - Создать в VPC subnet с названием public, сетью 192.168.10.0/24.
 - Создать в этой подсети NAT-инстанс, присвоив ему адрес 192.168.10.254. В качестве image_id использовать fd80mrhj8fl2oe87o4e1.
 - Создать в этой публичной подсети виртуалку с публичным IP, подключиться к ней и убедиться, что есть доступ к интернету.
3. Приватная подсеть.
 - Создать в VPC subnet с названием private, сетью 192.168.20.0/24.
 - Создать route table. Добавить статический маршрут, направляющий весь исходящий трафик private сети в NAT-инстанс.
 - Создать в этой приватной подсети виртуалку с внутренним IP, подключиться к ней через виртуалку, созданную ранее, и убедиться, что есть доступ к интернету.

Resource Terraform для Yandex Cloud:

- [VPC subnet](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet).
- [Route table](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_route_table).
- [Compute Instance](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance).

---
### Задание 2. AWS* (задание со звёздочкой)

Это необязательное задание. Его выполнение не влияет на получение зачёта по домашней работе.

**Что нужно сделать**

1. Создать пустую VPC с подсетью 10.10.0.0/16.
2. Публичная подсеть.

 - Создать в VPC subnet с названием public, сетью 10.10.1.0/24.
 - Разрешить в этой subnet присвоение public IP по-умолчанию.
 - Создать Internet gateway.
 - Добавить в таблицу маршрутизации маршрут, направляющий весь исходящий трафик в Internet gateway.
 - Создать security group с разрешающими правилами на SSH и ICMP. Привязать эту security group на все, создаваемые в этом ДЗ, виртуалки.
 - Создать в этой подсети виртуалку и убедиться, что инстанс имеет публичный IP. Подключиться к ней, убедиться, что есть доступ к интернету.
 - Добавить NAT gateway в public subnet.
3. Приватная подсеть.
 - Создать в VPC subnet с названием private, сетью 10.10.2.0/24.
 - Создать отдельную таблицу маршрутизации и привязать её к private подсети.
 - Добавить Route, направляющий весь исходящий трафик private сети в NAT.
 - Создать виртуалку в приватной сети.
 - Подключиться к ней по SSH по приватному IP через виртуалку, созданную ранее в публичной подсети, и убедиться, что с виртуалки есть выход в интернет.

Resource Terraform:

1. [VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc).
1. [Subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet).
1. [Internet Gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway).

### Правила приёма работы

Домашняя работа оформляется в своём Git репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.

---

### Ответ

Создадим terraform манифесты.\
Переменные проекта в [variables.tf](infrastructure/variables.tf). Значения переменных, которые содержат доступы к облаку держим в `.tfvars` файле со структурой `имя_переменной = значение`:

<details>
<summary>.tfvars example</summary>

```
yc_token     = "blahblah"
yc_cloud_id  = "blah"
yc_folder_id = "blah"
...
```

</details>

\
В [provider.tf](infrastructure/provider.tf) описываем настройки yandex cloud провайдера.

\
В [network.tf](infrastructure/network.tf) добавляем сетевую конфигурацию: cloud network, private/public subnets, route table для доступа к узлам в private подсети.

\
Необходимо организовать подключение из машины в public подсети в машину private подсети через ssh. Значит, на public машину необходимо добавить сгенерированный ssh ключ, а на целевую машину - открытую часть этого ключа. Для доступа к piblic и nat машинам буду использовать ключ сгенерированный заранее на своей рабочей машине. Все настройки по ssh конфигурации и прописыванию пользователя с ssh ключами попадают в файл [keys.tf](infrastructure/keys.tf). Шаблон для добавления пользователя и его ключа в шаблоне [metadata.tpl](infrastructure/metadata.tpl).

\
Наконец, конфигурация машин прописана в файле [main.tf](infrastructure/main.tf). 

\
Для отображения полученных ip адресов машин используем вывод, прописанных в файле [output.tf](infrastructure/output.tf).

После выполнения `terraform apply` получаем вывод:

```bash
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

vm_nat_external_ip = "178.154.223.137"
vm_nat_internal_ip = "192.168.10.254"
vm_private_external_ip = ""
vm_private_internal_ip = "192.168.20.19"
vm_public_external_ip = "178.154.206.131"
vm_public_internal_ip = "192.168.10.18"
```

\
Nat инстанс получил внутренний адрес `192.168.10.254`, прописанный вручную в конфигурации. Private инстанс не получил внешний ip адрес, т.к. не прописана опция `nat = true` для инстанса.\
Пробуем подключиться к Public машине и проверяем доступ в интернет:

<details>
<summary>connection check - public machine</summary>

```bash
vainoord@vivo-vnrd:~/study/netology_micros/14-clopro-01-network/infrastructure$ ssh netadmin@178.154.206.131

Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-172-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro
New release '22.04.3 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

Last login: Mon Mar  4 15:23:23 2024 from 194.12.146.146
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.


netadmin@fhmqddsd50i2llnhf80l:~$ curl -I https://netology.ru
HTTP/2 200 
date: Mon, 04 Mar 2024 15:24:59 GMT
content-type: text/html; charset=utf-8
x-frame-options: SOMEORIGIN
x-nextjs-cache: HIT
cache-control: s-maxage=300, stale-while-revalidate
strict-transport-security: max-age=15724800; includeSubDomains
cf-cache-status: DYNAMIC
server: cloudflare
cf-ray: 85f2e0558db55bb3-VIE
alt-svc: h3=":443"; ma=86400
```

</details>

Машина доступна для подключения, доступ к интернет имеется. Так же имеется сгенерированный ssh ключ для подключения к машине из private сети:

```bash
netadmin@fhmqddsd50i2llnhf80l:~$ ls -la ~/.ssh/
total 16
drwx------ 2 netadmin netadmin 4096 Mar  4 15:23 .
drwxr-xr-x 4 netadmin netadmin 4096 Mar  4 15:23 ..
-rw------- 1 netadmin netadmin  106 Mar  4 15:23 authorized_keys
-rw------- 1 netadmin netadmin  387 Mar  4 15:23 id_rsa
```

\
Протестируем private инстанс:

<details>
<summary>connection check - private machine</summary>

```bash
netadmin@fhmqddsd50i2llnhf80l:~$ ssh netadmin@192.168.20.19

Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-172-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

netadmin@fhm97od5rbhc71m94sng:~$ curl -I https://netology.ru
HTTP/2 200 
date: Mon, 04 Mar 2024 15:31:56 GMT
content-type: text/html; charset=utf-8
x-frame-options: SOMEORIGIN
x-nextjs-cache: HIT
cache-control: s-maxage=300, stale-while-revalidate
strict-transport-security: max-age=15724800; includeSubDomains
cf-cache-status: DYNAMIC
server: cloudflare
cf-ray: 85f2ea826f5c5bbc-VIE
alt-svc: h3=":443"; ma=86400
```

</details>

К инстансу подключение есть, доступ в интернет есть.

---