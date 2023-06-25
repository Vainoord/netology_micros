# Домашнее задание к занятию «Хранение в K8s. Часть 2»

### Цель задания

В тестовой среде Kubernetes нужно создать PV и продемострировать запись и хранение файлов.

------

### Чеклист готовности к домашнему заданию

1. Установленное K8s-решение (например, MicroK8S).
2. Установленный локальный kubectl.
3. Редактор YAML-файлов с подключенным GitHub-репозиторием.

------

### Дополнительные материалы для выполнения задания

1. [Инструкция по установке NFS в MicroK8S](https://microk8s.io/docs/nfs). 
2. [Описание Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/). 
3. [Описание динамического провижининга](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/). 
4. [Описание Multitool](https://github.com/wbitt/Network-MultiTool).

------

### Задание 1

**Что нужно сделать**

Создать Deployment приложения, использующего локальный PV, созданный вручную.

1. Создать Deployment приложения, состоящего из контейнеров busybox и multitool.
2. Создать PV и PVC для подключения папки на локальной ноде, которая будет использована в поде.
3. Продемонстрировать, что multitool может читать файл, в который busybox пишет каждые пять секунд в общей директории. 
4. Удалить Deployment и PVC. Продемонстрировать, что после этого произошло с PV. Пояснить, почему.
5. Продемонстрировать, что файл сохранился на локальном диске ноды. Удалить PV.  Продемонстрировать что произошло с файлом после удаления PV. Пояснить, почему.
5. Предоставить манифесты, а также скриншоты или вывод необходимых команд.

### Ответ

Перед созданием Persistent Volume и Persistent Volume Claim напишем манифест с Storage Class, в котором

<details>
<summary>Storage-class</summary>

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local
  namespace: ns-homework
# Using no-provisioner since we will use local storage
provisioner: kubernetes.io/no-provisioner
# Delay the binding and provisioning of a PersistentVolume until a Pod using the PersistentVolumeClaim is created
volumeBindingMode: WaitForFirstConsumer
```

</details>
<details>
<summary>PVC</summary>

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: ns-homework
spec:
  storageClassName: local
  # A default parameter of volumeMode - volume will be mounted with pre-installed filesystem 
  volumeMode: Filesystem
  # The volume can be mounted as read-write by many nodes
  accessModes:
    - ReadWriteMany
  resources:
    # 1Gb should be enough for test
    requests:
      storage: 1Gi
  volumeName: app-pv
```

</details>
<details>
<summary>PV</summary>

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-pv
  namespace: ns-homework
spec:
  # Settings the same as in PVC.yaml
  storageClassName: local
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  # Where PV will be mounted on the host machine
  hostPath:
    path: /pv_volume
  # Keep resources after deleting this PV
  persistentVolumeReclaimPolicy: Retain
```

</details>
<details>
<summary>Deployment</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  namespace: ns-homework
  labels:
    app: myapp-pvtest
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp-pvtest
  template:
    metadata:
      labels:
        app: myapp-pvtest
    spec:
      volumes:
      - name: app-pv-volume
        # Taking PVC name from PVC.yaml
        persistentVolumeClaim:
          claimName: app-pvc
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
        # Write something into file every 5 seconds
        command: ['sh', '-c', "sleep 10; while true; do (echo '====================================='; date; echo 'Testing writing into file') >> /pv_volume/messages; sleep 5; done"]
        volumeMounts:
          - name: app-pv-volume
            # Mount PV in /pv_volume for writing messages
            mountPath: /pv_volume
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
          - name: app-pv-volume
            mountPath: /pv_volume
```

</details>

\
Применим манифесты из посмотрим запись в файл в контейнере `multitool`:

<details>
<summary> PV volume check</summary>

\
<u>Сначала проверяем доступ к PV из контейнеров:</u>

```shell
vainoord@vnrd-mypc infrastructure $ kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
myapp-deployment-5d895997d8-wmg2h   2/2     Running   0          5m22s

vainoord@vnrd-mypc infrastructure $ kubectl exec -it myapp-deployment-5d895997d8-wmg2h -c multitool -- /bin/bash 

bash-5.1# tail -20 /pv_volume/messages 
Thu Jun 22 17:05:51 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:05:56 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:06:01 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:06:06 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:06:11 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:06:16 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:06:21 UTC 2023
Testing writing into file
```

\
<u>Из VM так же видно, что PV подключен и запись в файл видна:</u>

```shell
ubuntu@ubuntu-mk8s:/$ tail -20 /pv_volume/messages 
Thu Jun 22 17:07:06 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:07:11 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:07:16 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:07:21 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:07:26 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:07:31 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:07:36 UTC 2023
Testing writing into file
```

</details>

\
Удалим Deployment и PVC и посмотрим результат:

<details>
<summary>Deleting PVM and Deployment</summary>

```shell
vainoord@vnrd-mypc infrastructure $ kubectl delete deployments myapp-deployment   
deployment.apps "myapp-deployment" deleted

vainoord@vnrd-mypc infrastructure $ kubectl delete pvc app-pvc                 
persistentvolumeclaim "app-pvc" deleted
```

\
<u>Доступ к PV и файлам в ней из host VM остается:</u>

```shell
ubuntu@ubuntu-mk8s:/$ tail -20 /pv_volume/messages 
Thu Jun 22 17:10:26 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:10:31 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:10:36 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:10:41 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:10:46 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:10:51 UTC 2023
Testing writing into file
=====================================
Thu Jun 22 17:10:56 UTC 2023
Testing writing into file
```

</details>

\
<u>Если теперь в k8s удалить PV, то в Host VM папка и файл остаются, т.к. в PV манифесте был указан параметр `persistentVolumeReclaimPolicy: Retain`.
При необходимости папку необходимо удалять вручную.</u>

------

### Задание 2

**Что нужно сделать**

Создать Deployment приложения, которое может хранить файлы на NFS с динамическим созданием PV.

1. Включить и настроить NFS-сервер на MicroK8S.
2. Создать Deployment приложения состоящего из multitool, и подключить к нему PV, созданный автоматически на сервере NFS.
3. Продемонстрировать возможность чтения и записи файла изнутри пода. 
4. Предоставить манифесты, а также скриншоты или вывод необходимых команд.

### Ответ

Установим и настроим nfs сервер на VM по [инструкции из дополнительных материалов](https://microk8s.io/docs/nfs).\
Для k8s подготовим следующие манифесты: 

<details>
<summary>Storage class</summary>

```yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
  namespace: ns-homework
provisioner: nfs.csi.k8s.io
parameters:
  server: 192.168.150.4
  share: /srv/nfs
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - hard
  - nfsvers=4.1
```

</details>
<details>
<summary>PVC</summary>

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-nfs
spec:
  storageClassName: nfs-csi
  accessModes: [ReadWriteMany]
  resources:
    requests:
      storage: 2Gi
```

</details>
<details>
<summary>PV</summary>

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv-nfs
spec:
  storageClassName: nfs-csi
  capacity:
    storage: 2Gi
    volumeMode: Filesystem
  accessModes: [ReadWriteMany]
  persistentVolumeReclaimPolicy: Retain
  nfs:
    path: /srv/nfs
    server: 192.168.150.4
```

</details>
<details>
<summary>Deployment</summary>

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  namespace: ns-homework
  labels:
    app: myapp-pvtest-nfs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp-pvtest-nfs
  template:
    metadata:
      labels:
        app: myapp-pvtest-nfs
    spec:
      volumes:
      - name: app-pv-volume
        # Taking PVC name from PVC.yaml
        persistentVolumeClaim:
          claimName: my-pvc-nfs
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
        # Write something into file every 5 seconds
        command: ['sh', '-c', "sleep 10; while true; do (echo '====================================='; date; echo 'Testing writing into file ') >> /nfs/messages; sleep 5; done"]
        volumeMounts:
          - name: app-pv-volume
            # Mount PV in /nfs for writing messages
            mountPath: /nfs
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
          - name: app-pv-volume
            mountPath: /nfs
```

</details>

\
Применяем манифесты, подключаемся к контейнеру и проверяем запись лога в nfs:

<details>
<summary>NFS volume check</summary>

```shell
vainoord@vnrd-mypc infrastructure $ kubectl get pv  
NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                    STORAGECLASS   REASON   AGE
my-pv-nfs   2Gi        RWX            Retain           Bound    ns-homework/my-pvc-nfs   nfs-csi                 50m
vainoord@vnrd-mypc infrastructure $ kubectl get pvc
NAME         STATUS   VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS   AGE
my-pvc-nfs   Bound    my-pv-nfs   2Gi        RWX            nfs-csi        50m
```

```shell
vainoord@vnrd-mypc infrastructure $ kubectl get pods                  
NAME                                READY   STATUS    RESTARTS   AGE
myapp-deployment-86cb7855ff-r2xqr   2/2     Running   0          87s


vainoord@vnrd-mypc infrastructure $ kubectl exec -it myapp-deployment-86cb7855ff-r2xqr -c multitool -- /bin/bash


bash-5.1# tail -20 /nfs/messages 
Fri Jun 23 12:24:47 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:24:52 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:24:57 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:25:02 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:25:07 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:25:12 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:25:17 UTC 2023
Testing writing into file 
```

</details>

\
Проверяем службу и директорию `nfs` на VM:

<details>
<summary>NFS status on VM</summary>

```shell
ubuntu@ubuntu-mk8s:~$ sudo systemctl status nfs-kernel-server
● nfs-server.service - NFS server and services
     Loaded: loaded (/lib/systemd/system/nfs-server.service; enabled; vendor preset: enabled)
    Drop-In: /run/systemd/generator/nfs-server.service.d
             └─order-with-mounts.conf
     Active: active (exited) since Fri 2023-06-23 12:13:59 UTC; 9s ago
    Process: 125817 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
    Process: 125818 ExecStart=/usr/sbin/rpc.nfsd (code=exited, status=0/SUCCESS)
   Main PID: 125818 (code=exited, status=0/SUCCESS)
        CPU: 8ms

Jun 23 12:13:59 ubuntu-mk8s systemd[1]: Starting NFS server and services...
Jun 23 12:13:59 ubuntu-mk8s systemd[1]: Finished NFS server and services.


ubuntu@ubuntu-mk8s:~$ mount | grep nfs
nfsd on /proc/fs/nfsd type nfsd (rw,relatime)
192.168.150.4:/srv/nfs on /var/snap/microk8s/common/var/lib/kubelet/pods/84f27815-cebb-4519-9f07-54969d21c77f/volumes/kubernetes.io~nfs/my-pv-nfs type nfs4 (rw,relatime,vers=4.2,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.150.4,local_lock=none,addr=192.168.150.4)


ubuntu@ubuntu-mk8s:~$ netstat | grep :nfs
tcp        0      0 192-168-150-4.kuber:892 192-168-150-4.kuber:nfs ESTABLISHED
tcp        0      0 192-168-150-4.kuber:nfs 192-168-150-4.kuber:892 ESTABLISHED


ubuntu@ubuntu-mk8s:~$ tail -20 /srv/nfs/messages 
Fri Jun 23 12:25:57 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:26:02 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:26:07 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:26:13 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:26:18 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:26:23 UTC 2023
Testing writing into file 
=====================================
Fri Jun 23 12:26:28 UTC 2023
Testing writing into file 
```

</details>

------

### Правила приёма работы

1. Домашняя работа оформляется в своём Git-репозитории в файле README.md. Выполненное задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl`, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.