# Домашнее задание к занятию «Базовые объекты K8S»

### Цель задания

В тестовой среде для работы с Kubernetes, установленной в предыдущем ДЗ, необходимо развернуть Pod с приложением и подключиться к 
нему со своего локального компьютера. 

------

### Чеклист готовности к домашнему заданию

1. Установленное k8s-решение (например, MicroK8S).
2. Установленный локальный kubectl.
3. Редактор YAML-файлов с подключенным Git-репозиторием.

------

### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. Описание [Pod](https://kubernetes.io/docs/concepts/workloads/pods/) и примеры манифестов.
2. Описание [Service](https://kubernetes.io/docs/concepts/services-networking/service/).

------

### Задание 1. Создать Pod с именем hello-world

1. Создать манифест (yaml-конфигурацию) Pod.
2. Использовать image - gcr.io/kubernetes-e2e-test-images/echoserver:2.2.
3. Подключиться локально к Pod с помощью `kubectl port-forward` и вывести значение (curl или в браузере).

### Ответ

Pod создан, .yaml файл для pod hello-world:

<details>
<summary>hello-world.yaml</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-world
  labels:
    app: app-hello-world
spec:
  containers:
  - name: hello-world
    image: gcr.io/kubernetes-e2e-test-images/echoserver:2.2
    ports:
    - containerPort: 8080
```

```shell
ubuntu@ubuntu-mk8s:~$ microk8s kubectl port-forward pods/hello-world 18080:8080 --address='0.0.0.0'
Forwarding from 0.0.0.0:18080 -> 8080

```

</details>

\
Вывод curl:

<details>
<summary>curl pod output</summary>

```shell
vainoord@vnrd-mypc ~ $ curl http://84.201.175.24:18080/


Hostname: hello-world

Pod Information:
	-no pod information available-

Server values:
	server_version=nginx: 1.12.2 - lua: 10010

Request Information:
	client_address=127.0.0.1
	method=GET
	real path=/
	query=
	request_version=1.1
	request_scheme=http
	request_uri=http://84.201.175.24:8080/

Request Headers:
	accept=*/*  
	host=84.201.175.24:18080  
	user-agent=curl/7.87.0  

Request Body:
	-no body in request-

```

</details>

<details>
<summary>browser pod details</summary>

<img src="assets/scr1.png"
     alt="Dashboard"
     style="float: left; margin-right: 10px; margin-top: 10px;" />

</details>

------

### Задание 2. Создать Service и подключить его к Pod

1. Создать Pod с именем netology-web.
2. Использовать image — gcr.io/kubernetes-e2e-test-images/echoserver:2.2.
3. Создать Service с именем netology-svc и подключить к netology-web.
4. Подключиться локально к Service с помощью `kubectl port-forward` и вывести значение (curl или в браузере).

### Ответ

Созданы Pod `netology-web` и Service `netology-svc`:

<details>
<summary>Pod and service details</summary>
<table>
<tr>
<th>Pod config</th>
<th>Service config</th>
</tr>
<tr>
<td>

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: netology-echoserver
  name: netology-web
spec:
  containers:
    - image: gcr.io/kubernetes-e2e-test-images/echoserver:2.2
      name: netology-web
      ports:
        - containerPort: 8080
```

</td>
<td>

```yaml
apiVersion: v1
kind: Service
metadata: 
  name: netology-svc
spec:
  ports:
    - name: svc-netology-web
      port: 8080
  selector:
    app: netology-echoserver
```

</td>
</tr>
</table>

```shell
ubuntu@ubuntu-mk8s:~$ microk8s kubectl port-forward svc/netology-svc 18080:8080 --address="0.0.0.0"
Forwarding from 0.0.0.0:18080 -> 8080

```

</details>

\
Вывод curl:

<details>
<summary> curl svc output</summary>

```shell
vainoord@vnrd-mypc ~ $ curl http://84.201.175.24:18080/      


Hostname: netology-web

Pod Information:
	-no pod information available-

Server values:
	server_version=nginx: 1.12.2 - lua: 10010

Request Information:
	client_address=127.0.0.1
	method=GET
	real path=/
	query=
	request_version=1.1
	request_scheme=http
	request_uri=http://84.201.175.24:8080/

Request Headers:
	accept=*/*  
	host=84.201.175.24:18080  
	user-agent=curl/7.87.0  

Request Body:
	-no body in request-
```

</details>

<details>
<summary>browser svc details</summary>

<img src="assets/scr2.png"
     alt="Dashboard"
     style="float: left; margin-right: 10px; margin-top: 10px;" />

</details>

\
Итоговый вывод Pods:

<details>
<summary>Pod list</summary>

<img src="assets/scr3.png"
     alt="Dashboard"
     style="float: left; margin-right: 10px; margin-top: 10px;" />

</details>
------

### Правила приёма работы

1. Домашняя работа оформляется в своем Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл 
в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода команд `kubectl get pods`, а также скриншот результата подключения.
3. Репозиторий должен содержать файлы манифестов и ссылки на них в файле README.md.

------

### Критерии оценки
Зачёт — выполнены все задания, ответы даны в развернутой форме, приложены соответствующие скриншоты и файлы проекта, в выполненных 
заданиях нет противоречий и нарушения логики.

На доработку — задание выполнено частично или не выполнено, в логике выполнения заданий есть противоречия, существенные недостатки.
