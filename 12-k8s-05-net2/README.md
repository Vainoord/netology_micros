# Домашнее задание к занятию «Сетевое взаимодействие в K8S. Часть 2»

### Цель задания

В тестовой среде Kubernetes необходимо обеспечить доступ к двум приложениям снаружи кластера по разным путям.

------

### Чеклист готовности к домашнему заданию

1. Установленное k8s-решение (например, MicroK8S).
2. Установленный локальный kubectl.
3. Редактор YAML-файлов с подключённым Git-репозиторием.

------

### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Инструкция](https://microk8s.io/docs/getting-started) по установке MicroK8S.
2. [Описание](https://kubernetes.io/docs/concepts/services-networking/service/) Service.
3. [Описание](https://kubernetes.io/docs/concepts/services-networking/ingress/) Ingress.
4. [Описание](https://github.com/wbitt/Network-MultiTool) Multitool.

------

### Задание 1. Создать Deployment приложений backend и frontend

1. Создать Deployment приложения _frontend_ из образа nginx с количеством реплик 3 шт.
2. Создать Deployment приложения _backend_ из образа multitool. 
3. Добавить Service, которые обеспечат доступ к обоим приложениям внутри кластера. 
4. Продемонстрировать, что приложения видят друг друга с помощью Service.
5. Предоставить манифесты Deployment и Service в решении, а также скриншоты или вывод команды п.4.

### Ответ

Создадим два Deployment:

<details>
<summary>Deployment manifests</summary>
<table>
<tr>
<th>Deployment front</th>
<th>Deployment back</th>
</tr>
<tr>
<td>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-front
  namespace: ns-homework
  labels:
    app: dep-frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dep-frontend
  template:
    metadata:
      labels:
        app: dep-frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.23.4
        ports:
        - containerPort: 80
```

</td>
<td>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-back
  namespace: ns-homework
  labels:
    app: dep-backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dep-backend
  template:
    metadata:
      labels:
        app: dep-backend
    spec:
      containers:
      - name: multitool
        image: wbitt/network-multitool:latest
        env:
          - name: HTTP_PORT
            value: "80"
          - name: HTTPS_PORT
            value: "443"
        ports:
        - containerPort: 80
        - containerPort: 443
```

</td>
</tr>
</table>
</details>

\
Далее, два Service:

<details>
<summary>Service manifests</summary>
<table>
<tr>
<th>Service front</th>
<th>Service back</th>
</tr>
<tr>
<td>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-dev-front
  namespace: ns-homework
spec:
  selector:
    app: dep-frontend
  ports:
    - name: nginx
      protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

</td>
<td>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-dev-back
  namespace: ns-homework
spec:
  selector:
    app: dep-backend
  ports:
    - name: multitool-http
      protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

</td>
</tr>
</table>
</details>

\
Применяем манифесты, проверяем статус Deployments, Services и Pods:

```shell
vainoord@vnrd-mypc task5 $ kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
deployment-front   3/3     3            3           28h
deployment-back    1/1     1            1           28h

vainoord@vnrd-mypc task5 $ kubectl get services
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
svc-dev-front   ClusterIP   10.152.183.173   <none>        80/TCP     28h
svc-dev-back    ClusterIP   10.152.183.102   <none>        80/TCP     28h

vainoord@vnrd-mypc task5 $ kubectl get pods
NAME                               READY   STATUS    RESTARTS      AGE
deployment-front-c6f77ffdd-98mk5   1/1     Running   2 (11m ago)   28h
deployment-front-c6f77ffdd-jz448   1/1     Running   2 (11m ago)   28h
deployment-front-c6f77ffdd-64gd6   1/1     Running   2 (11m ago)   28h
deployment-back-7f78d4cb8f-6qgm7   1/1     Running   2 (11m ago)   28h
```

Проверяем доступность Services из Pods (возьмем Pod `deployment-front-c6f77ffdd-98mk5` из front service и Pod `deployment-back-7f78d4cb8f-6qgm7` из back service):

<details>
<summary>Checking apps accessibility from Pods</summary>

```shell
vainoord@vnrd-mypc ~ $ kubectl exec -i -t deployment-front-c6f77ffdd-98mk5 -- /bin/bash

root@deployment-front-c6f77ffdd-98mk5:/# curl http://svc-dev-back:80 
WBITT Network MultiTool (with NGINX) - deployment-back-7f78d4cb8f-6qgm7 - 10.1.128.216 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```

```shell
vainoord@vnrd-mypc ~ $ kubectl exec -i -t deployment-back-7f78d4cb8f-6qgm7 -- /bin/bash

bash-5.1# curl http://svc-dev-front:80
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
Проверка доступности Services из VM:

<details>
<summary>Checking apps accessibility from VM</summary>

```shell
ubuntu@ubuntu-mk8s:~$ curl http://svc-dev-front:80
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

```shell
ubuntu@ubuntu-mk8s:~$ curl http://svc-dev-back:8080
WBITT Network MultiTool (with NGINX) - deployment-back-59d96d7485-sbfzc - 10.1.128.213 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```

</details>

------

### Задание 2. Создать Ingress и обеспечить доступ к приложениям снаружи кластера

1. Включить Ingress-controller в MicroK8S.
2. Создать Ingress, обеспечивающий доступ снаружи по IP-адресу кластера MicroK8S так, чтобы при запросе только по адресу открывался _frontend_ а при добавлении /api - _backend_.
3. Продемонстрировать доступ с помощью браузера или `curl` с локального компьютера.
4. Предоставить манифесты и скриншоты или вывод команды п.2.

###  Ответ

Включаем ingress-controller командой `microk8s enable ingress`:

<details>
<summary>Enabled microk8s ingress</summary>

```shell
ubuntu@ubuntu-mk8s:~$ microk8s status
microk8s is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
addons:
  enabled:
    dashboard            # (core) The Kubernetes dashboard
    dns                  # (core) CoreDNS
    ha-cluster           # (core) Configure high availability on the current node
    helm                 # (core) Helm - the package manager for Kubernetes
    helm3                # (core) Helm 3 - the package manager for Kubernetes
    ingress              # (core) Ingress controller for external access
    metrics-server       # (core) K8s Metrics Server for API access to service metrics
```

</details>

Создадим Ingress manifest. При этом добавим аннотации `use-regex` и `rewrite-target`, поскольку для backend нужно выполнить перенаправление вызова.

<details>
<summary>Ingress http yaml</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingr-app-dev
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - host: myapp.dev.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: svc-dev-front
                port:
                  number: 80
          - path: /api(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: svc-dev-back
                port:
                  number: 80  
```

</details>

Ingress добавлен:

<details>
<summary>Ingress status</summary>

```shell
vainoord@vnrd-mypc task5 $ kubectl get ingress                  
NAME           CLASS    HOSTS             ADDRESS     PORTS   AGE
ingr-app-dev   public   myapp.dev.local   127.0.0.1   80      7m29s

vainoord@vnrd-mypc task5 $ kubectl describe ingress
Name:             ingr-app-dev
Labels:           <none>
Namespace:        ns-homework
Address:          127.0.0.1
Ingress Class:    public
Default backend:  <default>
Rules:
  Host             Path  Backends
  ----             ----  --------
  myapp.dev.local  
                   /      svc-dev-front:80 (10.1.128.194:80,10.1.128.206:80,10.1.128.209:80)
                   /api   svc-dev-back:80 (10.1.128.193:80)
Annotations:       <none>
Events:            <none>
```

</details>

Добавим в /etc/hosts запись '127.0.0.1 myapp.dev.local':

```shell
ubuntu@ubuntu-mk8s:~$ cat /etc/hosts
# Your system has configured 'manage_etc_hosts' as True.
# As a result, if you wish for changes to this file to persist
# then you will need to either
# a.) make changes to the master file in /etc/cloud/templates/hosts.debian.tmpl
# b.) change or remove the value of 'manage_etc_hosts' in
#     /etc/cloud/cloud.cfg or cloud-config from user-data
#
127.0.1.1 ubuntu-mk8s.my.yc ubuntu-mk8s
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

127.0.0.1 myapp.dev.local
```

\
Проверяем доступ до frontend:

<details>
<summary>Check http://myapp.dev.local/ host</summary>

```shell
ubuntu@ubuntu-mk8s:~$ curl http://myapp.dev.local
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
Теперь проверяем доступ до backend:

<details>
<summary>Check http://myapp.dev.local/api </summary>

```shell
ubuntu@ubuntu-mk8s:~$ curl http://myapp.dev.local/api
WBITT Network MultiTool (with NGINX) - deployment-back-7f78d4cb8f-6qgm7 - 10.1.128.215 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```

Получен ответ от nginx, который установлен в контейнере multitool.

</details>

------

### Правила приема работы

1. Домашняя работа оформляется в своем Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl` и скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.

------