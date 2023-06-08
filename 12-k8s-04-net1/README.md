# Домашнее задание к занятию «Сетевое взаимодействие в K8S. Часть 1»

### Цель задания

В тестовой среде Kubernetes необходимо обеспечить доступ к приложению, установленному в предыдущем ДЗ и состоящему из двух контейнеров, по разным портам в разные контейнеры как внутри кластера, так и снаружи.

------

### Чеклист готовности к домашнему заданию

1. Установленное k8s-решение (например, MicroK8S).
2. Установленный локальный kubectl.
3. Редактор YAML-файлов с подключённым Git-репозиторием.

------

### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Описание](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) Deployment и примеры манифестов.
2. [Описание](https://kubernetes.io/docs/concepts/services-networking/service/) Описание Service.
3. [Описание](https://github.com/wbitt/Network-MultiTool) Multitool.

------

### Задание 1. Создать Deployment и обеспечить доступ к контейнерам приложения по разным портам из другого Pod внутри кластера

1. Создать Deployment приложения, состоящего из двух контейнеров (nginx и multitool), с количеством реплик 3 шт.
2. Создать Service, который обеспечит доступ внутри кластера до контейнеров приложения из п.1 по порту 9001 — nginx 80, по 9002 — multitool 8080.
3. Создать отдельный Pod с приложением multitool и убедиться с помощью `curl`, что из пода есть доступ до приложения из п.1 по разным портам в разные контейнеры.
4. Продемонстрировать доступ с помощью `curl` по доменному имени сервиса.
5. Предоставить манифесты Deployment и Service в решении, а также скриншоты или вывод команды п.4.

### Ответ

Добавлена Deployment конфигурация:
<details>
<summary>Deployment config</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: homework-deployment
  namespace: ns-homework
  labels:
    app: netology-task
spec:
  replicas: 3
  selector:
    matchLabels:
      app: netology-task
  template:
    metadata:
      labels:
        app: netology-task
    spec:
      containers:
      - name: nginx
        image: nginx:1.23.4
        ports:
        - containerPort: 80
      - name: multitool
        image: wbitt/network-multitool
        ports:
        - containerPort: 1180
        - containerPort: 11443
        env:
          - name: HTTP_PORT
            value: "1180"
          - name: HTTPS_PORT
            value: "11443"
```

</details>

\
Конфигурация Service следующая:

<details>
<summary>Service config</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-homework
  namespace: ns-homework
spec:
  selector:
    app: netology-task
  ports:
    - name: nginx
      protocol: TCP
      port: 9001
      targetPort: 80
    - name: multitool-http
      protocol: TCP
      port: 9002
      targetPort: 1180
```

</details>

<details>
<summary>Pod config</summary>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-multitool
  namespace: ns-homework
  labels:
    app: netology-sub-multitool
spec:
  containers:
  - name: multitool-2
    image: wbitt/network-multitool
    env:
      - name: HTTP_PORT
        value: "8099"
      - name: HTTPS_PORT
        value: "44399"
    ports:
    - containerPort: 8099
    - containerPort: 44399
```

</details>

```shell
vainoord@vnrd-mypc task3 $ kubectl get deployments               
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
homework-deployment   3/3     3            3           16h

vainoord@vnrd-mypc task3 $ kubectl get services   
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
svc-homework   ClusterIP   10.152.183.180   <none>        9001/TCP,9002/TCP   16h

vainoord@vnrd-mypc task3 $ kubectl get pods
NAME                                   READY   STATUS    RESTARTS      AGE
homework-deployment-5fff569859-c9gnb   2/2     Running   2 (27m ago)   16h
homework-deployment-5fff569859-vb7gc   2/2     Running   2 (27m ago)   16h
homework-deployment-5fff569859-rshfs   2/2     Running   2 (27m ago)   16h
pod-multitool                          1/1     Running   0             57s
```

\
Подключение к `pod-multitool` через команду `kubectl exec -it pod-multitool  -- /bin/bash`.\
Результаты выполнения команды curl на `http://svc-homework:9001`:

<details>
<summary>Curl service with port 9001</summary>

```shell
bash-5.1# curl http://svc-homework:9001
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
bash-5.1# curl http://svc-homework:9002
curl: (7) Failed to connect to svc-homework port 9002 after 1 ms: Connection refused
bash-5.1# exit
exit
command terminated with exit code 7
vainoord@vnrd-mypc task3 $ vim netology-service.yaml 
vainoord@vnrd-mypc task3 $ kubectl apply -f netology-service.yaml 
service/svc-homework configured
vainoord@vnrd-mypc task3 $ kubectl exec -i -t pod-multitool -- /bin/bash
bash-5.1# curl http://svc-homework:9001
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

</details>

\
И curl на `http://svc-homework:9002`:

<details>
<summary>Curl service with port 9002</summary>

```shell
bash-5.1# curl http://svc-homework:9002
WBITT Network MultiTool (with NGINX) - homework-deployment-5fff569859-vb7gc - 10.1.128.253 - HTTP: 1180 , HTTPS: 11443 . (Formerly praqma/network-multitool)
```

</details>

------

### Задание 2. Создать Service и обеспечить доступ к приложениям снаружи кластера

1. Создать отдельный Service приложения из Задания 1 с возможностью доступа снаружи кластера к nginx, используя тип NodePort.
2. Продемонстрировать доступ с помощью браузера или `curl` с локального компьютера.
3. Предоставить манифест и Service в решении, а также скриншоты или вывод команды п.2.


### Ответ

Service для доступа снаружи кластера к nginx. Nodeport укажем 30080, т.к. он должен быть из диапазона 30000-32767:

<details>
<summary>Service nginx</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx-nodeport
  namespace: ns-homework
spec:
  selector:
    app: netology-task
  ports:
    - name: nginx
      protocol: TCP
      port: 9001
      targetPort: 80
      nodeport: 30080
  type: NodePort
  ```

</details>

\
Итого в namespace ns-homework уже два service:

```shell
vainoord@vnrd-mypc task3 $ kubectl get services                        
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
svc-homework         ClusterIP   10.152.183.180   <none>        9001/TCP,9002/TCP   3d8h
svc-nginx-nodeport   NodePort    10.152.183.213   <none>        9001:30080/TCP      3m
```

<details>
<summary>Curl service with port 9001 from VM</summary>

```shell
ubuntu@ubuntu-mk8s:~$ curl http://svc-nginx-nodeport:9001
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

</details>

--- 

### Manifest yaml:

[k8s manifest](k8s.yaml)

------

### Правила приёма работы

1. Домашняя работа оформляется в своем Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl` и скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.