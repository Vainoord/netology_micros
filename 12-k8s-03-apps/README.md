# Домашнее задание к занятию «Запуск приложений в K8S»

### Цель задания

В тестовой среде для работы с Kubernetes, установленной в предыдущем ДЗ, необходимо развернуть Deployment с приложением, состоящим из нескольких контейнеров, и масштабировать его.

------

### Чеклист готовности к домашнему заданию

1. Установленное k8s-решение (например, MicroK8S).
2. Установленный локальный kubectl.
3. Редактор YAML-файлов с подключённым git-репозиторием.

------

### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Описание](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) Deployment и примеры манифестов.
2. [Описание](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) Init-контейнеров.
3. [Описание](https://github.com/wbitt/Network-MultiTool) Multitool.

------

### Задание 1. Создать Deployment и обеспечить доступ к репликам приложения из другого Pod

1. Создать Deployment приложения, состоящего из двух контейнеров — nginx и multitool. Решить возникшую ошибку.
2. После запуска увеличить количество реплик работающего приложения до 2.
3. Продемонстрировать количество подов до и после масштабирования.
4. Создать Service, который обеспечит доступ до реплик приложений из п.1.
5. Создать отдельный Pod с приложением multitool и убедиться с помощью `curl`, что из пода есть доступ до приложений из п.1.

### Ответ

Создадим namespace ns-homework:

<details>
<summary>namespace yaml file</summary>

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ns-homework
  labels:
    app: netology-task
```

</details>

\
Создадим Deployment с двумя контейнерами, nginx и praqma/Network-MultiTool.

<details>
<summary>deployment yaml file</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: homework-deployment
  namespace: ns-homework
  labels:
    app: netology-task
spec:
  replicas: 1
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
          name: http-port
        - containerPort: 11443
          name: https-port
```

</details>

\
С такой конфигурацией Pod не запускается - контейнер multitool выдает ошибку с портом 80. Порт занят контейнером nginx из этого же Deployment.

<details>
<summary> pod error</summary>

```shell
vainoord@vnrd-mypc k8s $ kubectl describe pod homework-deployment-9d95746d6-gcztr

...
Containers:
  nginx:
    Container ID:   containerd://eec9702e045108564d3e8e5a803303a7bc53b7e4abaf47e87aec55aa098064c9
    Image:          nginx:1.23.4
    Image ID:       docker.io/library/nginx@sha256:480868e8c8c797794257e2abd88d0f9a8809b2fe956cbfbc05dcc0bca1f7cd43
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 22 May 2023 15:05:46 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-srbch (ro)
  multitool:
    Container ID:   containerd://a969edff8cb38c1c3f3808e7d9a21c6812d6280b12c5195aca093dfaaad0599d
    Image:          wbitt/network-multitool
    Image ID:       docker.io/wbitt/network-multitool@sha256:82a5ea955024390d6b438ce22ccc75c98b481bf00e57c13e9a9cc1458eb92652
    Ports:          1180/TCP, 11443/TCP
    Host Ports:     0/TCP, 0/TCP
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Mon, 22 May 2023 15:09:07 +0200
      Finished:     Mon, 22 May 2023 15:09:09 +0200
    Ready:          False
    Restart Count:  5
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-srbch (ro)
...

```

```shell
vainoord@vnrd-mypc k8s $ kubectl logs homework-deployment-9d95746d6-gcztr -c multitool
The directory /usr/share/nginx/html is not mounted.
Therefore, over-writing the default index.html file with some useful information:
WBITT Network MultiTool (with NGINX) - homework-deployment-9d95746d6-gcztr - 10.1.128.221 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
2023/05/22 13:11:54 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address in use)
2023/05/22 13:11:54 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address in use)
2023/05/22 13:11:54 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address in use)
2023/05/22 13:11:54 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address in use)
2023/05/22 13:11:54 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address in use)
2023/05/22 13:11:54 [emerg] 1#1: still could not bind()
```

</details>

\
Исправить ошибку можно в конфигурации Deployment, через переменные окружения `HTTP_PORT` и `HTTPS_PORT` контейнера multitool.
В итоге deployment выглядит так:

<details>
<summary>deployment yaml file - fixed</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: homework-deployment
  namespace: ns-homework
  labels:
    app: netology-task
spec:
  replicas: 1
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
          name: http-port
        - containerPort: 11443
          name: https-port
        env:
          - name: HTTP_PORT
            value: "1180"
          - name: HTTPS_PORT
            value: "11443"
```

</details>

Ошибка исправлена.

```shell
vainoord@vnrd-mypc k8s $ kubectl get deployments
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
homework-deployment   1/1     1            1           2m43s
```

\
Увеличим количество реплик до 2. В deployment установим значение `replicas: 2`.

```shell
vainoord@vnrd-mypc k8s $ kubectl get pods
NAME                                   READY   STATUS    RESTARTS   AGE
homework-deployment-5fff569859-7zz8d   2/2     Running   0          26m
```

```shell
vainoord@vnrd-mypc k8s $ kubectl get pods                         
NAME                                   READY   STATUS    RESTARTS   AGE
homework-deployment-5fff569859-7zz8d   2/2     Running   0          30m
homework-deployment-5fff569859-t4x8b   2/2     Running   0          9s
```

Теперь создадим service для обеспечения доступа к репликам приложений nginx и multitool. В сервис включим описание портов 80, 1180 и 11443 этих приложений.

<details>
<summary>service yaml file</summary>

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
      port: 80
      targetPort: 80
    - name: multitool-http
      protocol: TCP
      port: 1180
      targetPort: 1180
    - name: multitool-https
      protocol: TCP
      port: 11443
      targetPort: 11443
```

</details>

```shell
vainoord@vnrd-mypc k8s $ kubectl get services                 
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                     AGE
svc-homework   ClusterIP   10.152.183.27   <none>        80/TCP,1180/TCP,11443/TCP   4m33s
```

Создадим отдельный Pod с multitool контейнером.

<details>
<summary>mutlitool pod</summary>

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
vainoord@vnrd-mypc k8s $ kubectl get pods 
NAME                                   READY   STATUS    RESTARTS   AGE
homework-deployment-5fff569859-7zz8d   2/2     Running   0          75m
homework-deployment-5fff569859-t4x8b   2/2     Running   0          45m
pod-multitool                          1/1     Running   0          70s
```

\
Проверяем доступность до приложений через service:

<details>
<summary>curl check</summary>

```shell
vainoord@vnrd-mypc k8s $ kubectl exec -it pod-multitool -- /bin/bash

bash-5.1# curl 10.152.183.27:1180
WBITT Network MultiTool (with NGINX) - homework-deployment-5fff569859-7zz8d - 10.1.128.220 - HTTP: 1180 , HTTPS: 11443 . (Formerly praqma/network-multitool)

bash-5.1# curl 10.152.183.27:80
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

------

### Задание 2. Создать Deployment и обеспечить старт основного контейнера при выполнении условий

1. Создать Deployment приложения nginx и обеспечить старт контейнера только после того, как будет запущен сервис этого приложения.
2. Убедиться, что nginx не стартует. В качестве Init-контейнера взять busybox.
3. Создать и запустить Service. Убедиться, что Init запустился.
4. Продемонстрировать состояние пода до и после запуска сервиса.

### Ответ

Задаем новый Deployment с init контейнером busybox:

<details>
<summary>deployment2 yaml file</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dp-test-init-container
  namespace: ns-homework
  labels:
    app: netology-task
spec:
  replicas: 1
  selector:
    matchLabels:
      app: netology-task
  template:
    metadata:
      labels:
        app: netology-task
    spec:
      initContainers:
      - name: busybox-init-cont
        image: busybox:latest
        command: ['sh', '-c', "until nslookup svc-myservice.ns-homework.svc.cluster.local; do echo waiting for svc-myservice; sleep 2; done"]
      containers:
      - name: nginx-cont
        image: nginx:1.23.4
        ports:
        - containerPort: 80

```

</details>

\
Pod не запустился, поскольку нет Service с именен `svc-myservice`:

```shell
vainoord@vnrd-mypc k8s $ kubectl get deployments -l app=netology-task
NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
dp-test-init-container   0/1     1            0           105s
vainoord@vnrd-mypc k8s $ kubectl get pods -l app=netology-task       
NAME                                      READY   STATUS     RESTARTS   AGE
dp-test-init-container-59b6c6cc4d-f6pvv   0/1     Init:0/1   0          2m8s

```

Создадим и добавим Service `svc-myservice`:

<details>
<summary>service2 yaml file</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: svc-myservice
spec:
  selector:
    app: netology-task
  ports:
    - name: nginx-cont
      protocol: TCP
      port: 80
      targetPort: 80

```

</details>

\
Pods меняют статус с `Pending` на `Running`. Контейнер с Busybox выключился после успешной выполнении команды, контейнер nginx запущен и имеет статус `Running`. Хотя потребовалось подождать почти час.

<details>
<summary>Busybox container last log</summary>

```shell
vainoord@vnrd-mypc k8s $ kubectl logs dp-test-init-container-54bbcbd579-6brvb -c busybox-init-cont

...

waiting for svc-myservice
;; connection timed out; no servers could be reached

waiting for svc-myservice
nslookup: write to '10.152.183.10': Connection refused
;; connection timed out; no servers could be reached

waiting for svc-myservice
nslookup: write to '10.152.183.10': Connection refused
nslookup: write to '10.152.183.10': Connection refused
;; connection timed out; no servers could be reached

waiting for svc-myservice
;; connection timed out; no servers could be reached

waiting for svc-myservice
nslookup: write to '10.152.183.10': Connection refused
Server:		10.152.183.10
Address:	10.152.183.10:53

Name:	svc-myservice.ns-homework.svc.cluster.local
Address: 10.152.183.159
```
</details>

<details>
<summary>Pods status</summary>

```shell
vainoord@vnrd-mypc k8s $ kubectl get pods     
NAME                                      READY   STATUS    RESTARTS   AGE
dp-test-init-container-54bbcbd579-6brvb   1/1     Running   0          11h
```

```shell
vainoord@vnrd-mypc k8s $ kubectl describe pods
Name:             dp-test-init-container-54bbcbd579-6brvb
Namespace:        ns-homework
Priority:         0
Service Account:  default
Node:             ubuntu-mk8s/192.168.150.4
Start Time:       Tue, 23 May 2023 23:31:04 +0200
Labels:           app=netology-task
                  pod-template-hash=54bbcbd579
Annotations:      cni.projectcalico.org/containerID: f5d24d95971ed32d202ea61a93bf447f4ff8c5e4b369a6d55f6d3307e82eaf06
                  cni.projectcalico.org/podIP: 10.1.128.217/32
                  cni.projectcalico.org/podIPs: 10.1.128.217/32
Status:           Running
IP:               10.1.128.217
IPs:
  IP:           10.1.128.217
Controlled By:  ReplicaSet/dp-test-init-container-54bbcbd579
Init Containers:
  busybox-init-cont:
    Container ID:  containerd://c93f1d2735fe02803a5d99740af1524a6532d6d87ffcbf8c9562e851899c5e1d
    Image:         busybox:latest
    Image ID:      docker.io/library/busybox@sha256:560af6915bfc8d7630e50e212e08242d37b63bd5c1ccf9bd4acccf116e262d5b
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      until nslookup svc-myservice.ns-homework.svc.cluster.local; do echo waiting for svc-myservice; sleep 2; done
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Wed, 24 May 2023 09:51:11 +0200
      Finished:     Wed, 24 May 2023 10:37:52 +0200
    Ready:          True
    Restart Count:  1
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-9kksl (ro)
Containers:
  nginx-cont:
    Container ID:   containerd://cc11f3456301fe3ccd3af6bea068d5beef7d971c21b2aaf162cbd7f5df7323fe
    Image:          nginx:1.23.4
    Image ID:       docker.io/library/nginx@sha256:480868e8c8c797794257e2abd88d0f9a8809b2fe956cbfbc05dcc0bca1f7cd43
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Wed, 24 May 2023 10:37:54 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-9kksl (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-9kksl:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>
```

</details>

------

### Правила приема работы

1. Домашняя работа оформляется в своем Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl` и скриншоты результатов.
3. Репозиторий должен содержать файлы манифестов и ссылки на них в файле README.md.

------