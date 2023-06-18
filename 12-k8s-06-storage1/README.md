# Домашнее задание к занятию «Хранение в K8s. Часть 1»

### Цель задания

В тестовой среде Kubernetes нужно обеспечить обмен файлами между контейнерам пода и доступ к логам ноды.

------

### Чеклист готовности к домашнему заданию

1. Установленное K8s-решение (например, MicroK8S).
2. Установленный локальный kubectl.
3. Редактор YAML-файлов с подключенным GitHub-репозиторием.

------

### Дополнительные материалы для выполнения задания

1. [Инструкция по установке MicroK8S](https://microk8s.io/docs/getting-started).
2. [Описание Volumes](https://kubernetes.io/docs/concepts/storage/volumes/).
3. [Описание Multitool](https://github.com/wbitt/Network-MultiTool).

------

### Задание 1 

**Что нужно сделать**

Создать Deployment приложения, состоящего из двух контейнеров и обменивающихся данными.

1. Создать Deployment приложения, состоящего из контейнеров busybox и multitool.
2. Сделать так, чтобы busybox писал каждые пять секунд в некий файл в общей директории.
3. Обеспечить возможность чтения файла контейнером multitool.
4. Продемонстрировать, что multitool может читать файл, который периодоически обновляется.
5. Предоставить манифесты Deployment в решении, а также скриншоты или вывод команды из п. 4.

### Ответ

Создадим Deployment. Тип volume - emptyDir. Контейнер busybox будет записывать в /log_inputpinglog файл дату и пинг google.com каждые 10 секунд:

<details>
<summary>Deployment manifest</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  namespace: ns-homework
  labels:
    app: myapp-testvolume
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp-testvolume
  template:
    metadata:
      labels:
        app: myapp-testvolume
    spec:
      containers:
      - name: busybox
        image: busybox:stable
        resources:
          requests:
            memory: "64Mi"
            cpu: "125m"
          limits:
            memory: "128Mi"
            cpu: "250m"
        command: ['sh', '-c', "sleep 10; while true; do (echo '====================================='; date; ping -c 3 google.com) >> /log_output/pinglog; sleep 10; done"]
        volumeMounts:
          - name: log-volume
            # mount volume in / for log collecting
            mountPath: /log_output
      - name: multitool
        image: wbitt/network-multitool:latest
        resources:
          requests:
            memory: "64Mi"
            cpu: "125m"
          limits:
            memory: "128Mi"
            cpu: "250m"
        env:
          - name: HTTP_PORT
            value: "80"
          - name: HTTPS_PORT
            value: "443"
        ports:
        - containerPort: 80
        - containerPort: 443
        volumeMounts:
          - name: log-volume
            mountPath: /log_input
      volumes:
      - name: log-volume
        emptyDir: {}

```

</details>

\
Посмотрим работу наполнения файла и доступность его для чтения из `multitool` контейнера:

<details>
<summary>Inspecting multitool container</summary>

```shell
vainoord@vnrd-mypc netology_micros $ kubectl get pods                                                            
NAME                                READY   STATUS    RESTARTS   AGE
myapp-deployment-76fb9954b8-2px24   2/2     Running   0          13m

vainoord@vnrd-mypc netology_micros $ kubectl exec -it myapp-deployment-76fb9954b8-2px24 -c multitool -- /bin/bash

bash-5.1# ls -la /log_input/
total 44
drwxrwxrwx    2 root     root          4096 Jun 18 09:37 .
drwxr-xr-x    1 root     root          4096 Jun 18 09:37 ..
-rw-r--r--    1 root     root         30776 Jun 18 09:51 pinglog

bash-5.1# tail -20 /log_input/pinglog 
=====================================
Sun Jun 18 09:52:30 UTC 2023
PING google.com (142.251.1.113): 56 data bytes
64 bytes from 142.251.1.113: seq=0 ttl=60 time=28.468 ms
64 bytes from 142.251.1.113: seq=1 ttl=60 time=28.399 ms
64 bytes from 142.251.1.113: seq=2 ttl=60 time=28.717 ms

--- google.com ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 28.399/28.528/28.717 ms
=====================================
Sun Jun 18 09:52:42 UTC 2023
PING google.com (142.251.1.102): 56 data bytes
64 bytes from 142.251.1.102: seq=0 ttl=60 time=23.282 ms
64 bytes from 142.251.1.102: seq=1 ttl=60 time=23.246 ms
64 bytes from 142.251.1.102: seq=2 ttl=60 time=23.408 ms

--- google.com ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 23.246/23.312/23.408 ms
```

</details>

------

### Задание 2

**Что нужно сделать**

Создать DaemonSet приложения, которое может прочитать логи ноды.

1. Создать DaemonSet приложения, состоящего из multitool.
2. Обеспечить возможность чтения файла `/var/log/syslog` кластера MicroK8S.
3. Продемонстрировать возможность чтения файла изнутри пода.
4. Предоставить манифесты Deployment, а также скриншоты или вывод команды из п. 2.

### Ответ

Создаем daemonset приложения с контейнером multitool:

<details>
<summary>Daemonset config</summary>

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-reader
  namespace: ns-homework
  labels:
    app: log-reader
spec:
  selector:
    matchLabels:
      app: log-reader
  template:
    metadata:
      labels:
        app: log-reader
    spec:
      containers:
      - name: multitool
        image: wbitt/network-multitool:latest
        resources:
          requests:
            memory: "64Mi"
            cpu: "125m"
          limits:
            memory: "128Mi"
            cpu: "250m"
        env:
          - name: HTTP_PORT
            value: "80"
          - name: HTTPS_PORT
            value: "443"
        ports:
        - containerPort: 80
        - containerPort: 443
        volumeMounts:
        - name: dir-syslog
          # standard logs location directory
          mountPath: /var/log
      volumes:
      - name: dir-syslog
        hostPath:
          path: /var/log
          type: ""
```

</details>

\
Затем посмотрим доступность `syslog` из пода.

```shel
vainoord@vnrd-mypc ~ $ kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
myapp-deployment-76fb9954b8-2px24   2/2     Running   0          37m
log-reader-t5zpm                    1/1     Running   0          10m
```

<details>
<summary>Checking pods</summary>

```shell 
vainoord@vnrd-mypc netology_micros $ kubectl exec -it myapp-deployment-76fb9954b8-2px24 -c multitool -- /bin/bash

bash-5.1# ls -la /var/log
total 20
drwxr-xr-x    1 root     root          4096 Dec 19  2021 .
drwxr-xr-x    1 root     root          4096 Dec 19  2021 ..
drwxr-xr-x    1 nginx    nginx         4096 Jun 18 09:37 nginx
```

```shell
vainoord@vnrd-mypc netology_micros $ kubectl exec -it log-reader-t5zpm -c multitool -- /bin/bash

bash-5.1# ls -la /var/log/
total 22744
drwxrwxr-x   12 root     113           4096 Jun 18 09:13 .
drwxr-xr-x    1 root     root          4096 Dec 19  2021 ..
-rw-r--r--    1 root     root             0 Jun 16 14:49 alternatives.log
-rw-r--r--    1 root     root          6676 Jun 15 21:27 alternatives.log.1
-rw-r--r--    1 root     root           436 May 17 20:09 alternatives.log.2.gz
drwxr-xr-x    2 root     root          4096 Jun 15 21:27 apt
-rw-r-----    1 107      adm           2036 Jun 18 10:02 auth.log
-rw-r-----    1 107      adm         247171 Jun 18 09:13 auth.log.1
-rw-r-----    1 107      adm          79125 Jun 11 21:00 auth.log.2.gz
-rw-r-----    1 107      adm            514 Jun  4 16:36 auth.log.3.gz
-rw-r-----    1 107      adm           5570 May 28 16:48 auth.log.4.gz
-rw-rw----    1 root     43          660480 Jun 18 09:22 btmp
-rw-rw----    1 root     43          190080 May 22 14:39 btmp.1
drwxr-xr-x    3 root     root          4096 Apr 15 10:41 calico
-rw-r-----    1 root     adm         153919 Jun 18 09:14 cloud-init-output.log
-rw-r-----    1 107      adm        6133673 Jun 18 09:14 cloud-init.log
drwxr-xr-x    2 root     root         12288 Jun 18 10:04 containers
drwxr-xr-x    2 root     root          4096 Apr 18  2022 dist-upgrade
-rw-r-----    1 root     adm          77044 Jun 18 09:13 dmesg
-rw-r-----    1 root     adm          78061 Jun 16 16:44 dmesg.0
-rw-r-----    1 root     adm          18666 Jun 16 14:49 dmesg.1.gz
-rw-r-----    1 root     adm          18497 Jun 15 21:05 dmesg.2.gz
-rw-r-----    1 root     adm          18453 Jun 14 15:12 dmesg.3.gz
-rw-r-----    1 root     adm          18713 Jun 12 11:24 dmesg.4.gz
-rw-r--r--    1 root     root         31917 Jun 15 21:27 dpkg.log
-rw-r--r--    1 root     root         32520 May 24 08:46 dpkg.log.1
-rw-r--r--    1 root     root           574 Apr 15 10:41 dpkg.log.2.gz
drwxr-x---    3 root     adm           4096 Apr  7 16:31 installer
drwxr-sr-x    4 root     nginx         4096 Apr 15 10:31 journal
-rw-r-----    1 107      adm           5611 Jun 18 10:04 kern.log
-rw-r-----    1 107      adm         723672 Jun 18 09:13 kern.log.1
-rw-r-----    1 107      adm         331065 Jun 11 21:00 kern.log.2.gz
-rw-r-----    1 107      adm          18651 Jun  4 16:36 kern.log.3.gz
-rw-r-----    1 107      adm         201419 May 28 16:48 kern.log.4.gz
drwxr-xr-x    2 111      117           4096 Apr 15 10:33 landscape
-rw-rw-r--    1 root     43          292292 Jun 14 15:14 lastlog
drwxr-xr-x   11 root     root          4096 Jun 18 10:04 pods
drwx------    2 root     root          4096 Apr 21  2022 private
-rw-r-----    1 107      adm        1273013 Jun 18 10:05 syslog
-rw-r-----    1 107      adm        8689136 Jun 18 09:13 syslog.1
-rw-r-----    1 107      adm        2493285 Jun 11 21:00 syslog.2.gz
-rw-r-----    1 107      adm          87312 Jun  4 16:36 syslog.3.gz
-rw-r-----    1 107      adm        1314736 May 28 16:48 syslog.4.gz
-rw-r--r--    1 root     root          3822 Jun 18 09:31 ubuntu-advantage-timer.log
-rw-r--r--    1 root     root          1911 May 24 08:46 ubuntu-advantage-timer.log.1
-rw-r--r--    1 root     root           213 Apr 17 05:41 ubuntu-advantage-timer.log.2.gz
-rw-r--r--    1 root     root          3759 Jun 12 14:43 ubuntu-advantage.log
-rw-r--r--    1 root     root          3328 May 24 09:20 ubuntu-advantage.log.1
-rw-r--r--    1 root     root           710 Apr 16 16:12 ubuntu-advantage.log.2.gz
drwxr-x---    2 root     adm           4096 Jun  4 16:36 unattended-upgrades
-rw-rw-r--    1 root     43          181632 Jun 18 09:14 wtmp
```
</details>

\
Проверяем чтение `syslog`:

<details>
<summary>/var/log/syslog</summary>

```shell
bash-5.1# tail -15 /var/log/syslog
Jun 18 10:05:51 ubuntu-mk8s microk8s.daemon-kubelite[1341]: Trace[1329737242]: [605.913464ms] [605.913464ms] END
Jun 18 10:05:53 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-bdcbdf8f5e5aa3fec43d44a2487f475a8679ffaac03c796333092151d339fa5c-runc.s0xUF3.mount: Deactivated successfully.
Jun 18 10:05:56 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-8908b28957140cc2cc312622d77f06ac67e7a1ab2f756667a8e3673303e6e757-runc.dDMkRK.mount: Deactivated successfully.
Jun 18 10:05:59 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-bdcbdf8f5e5aa3fec43d44a2487f475a8679ffaac03c796333092151d339fa5c-runc.JY1EwK.mount: Deactivated successfully.
Jun 18 10:06:06 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-8908b28957140cc2cc312622d77f06ac67e7a1ab2f756667a8e3673303e6e757-runc.dvTYr6.mount: Deactivated successfully.
Jun 18 10:06:09 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-bdcbdf8f5e5aa3fec43d44a2487f475a8679ffaac03c796333092151d339fa5c-runc.Lmazr6.mount: Deactivated successfully.
Jun 18 10:06:10 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-8908b28957140cc2cc312622d77f06ac67e7a1ab2f756667a8e3673303e6e757-runc.Stx1G7.mount: Deactivated successfully.
Jun 18 10:06:13 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-bdcbdf8f5e5aa3fec43d44a2487f475a8679ffaac03c796333092151d339fa5c-runc.uVfZ5R.mount: Deactivated successfully.
Jun 18 10:06:16 ubuntu-mk8s microk8s.daemon-kubelite[1341]: I0618 10:06:16.435343    1341 trace.go:219] Trace[1702764968]: "Update" accept:application/vnd.kubernetes.protobuf,application/json,audit-id:f8d54f7b-990f-401c-8a36-97bb5c7b56e2,client:127.0.0.1,protocol:HTTP/2.0,resource:leases,scope:resource,url:/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/ubuntu-mk8s,user-agent:kubelite/v1.26.5 (linux/amd64) kubernetes/890a139,verb:PUT (18-Jun-2023 10:06:14.900) (total time: 1535ms):
Jun 18 10:06:16 ubuntu-mk8s microk8s.daemon-kubelite[1341]: Trace[1702764968]: ["GuaranteedUpdate etcd3" audit-id:f8d54f7b-990f-401c-8a36-97bb5c7b56e2,key:/leases/kube-node-lease/ubuntu-mk8s,type:*coordination.Lease,resource:leases.coordination.k8s.io 1535ms (10:06:14.900)
Jun 18 10:06:16 ubuntu-mk8s microk8s.daemon-kubelite[1341]: Trace[1702764968]:  ---"Txn call completed" 1534ms (10:06:16.435)]
Jun 18 10:06:16 ubuntu-mk8s microk8s.daemon-kubelite[1341]: Trace[1702764968]: [1.535227658s] [1.535227658s] END
Jun 18 10:06:20 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-8908b28957140cc2cc312622d77f06ac67e7a1ab2f756667a8e3673303e6e757-runc.iFPlot.mount: Deactivated successfully.
Jun 18 10:06:23 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-bdcbdf8f5e5aa3fec43d44a2487f475a8679ffaac03c796333092151d339fa5c-runc.5R0Ic7.mount: Deactivated successfully.
Jun 18 10:06:26 ubuntu-mk8s systemd[1]: run-containerd-runc-k8s.io-8908b28957140cc2cc312622d77f06ac67e7a1ab2f756667a8e3673303e6e757-runc.ewIZbO.mount: Deactivated successfully.
```

</details>
------

### Правила приёма работы

1. Домашняя работа оформляется в своём Git-репозитории в файле README.md. Выполненное задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl`, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.

------