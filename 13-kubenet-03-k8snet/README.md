# Домашнее задание к занятию «Как работает сеть в K8s»

### Цель задания

Настроить сетевую политику доступа к подам.

### Чеклист готовности к домашнему заданию

1. Кластер K8s с установленным сетевым плагином Calico.

### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Документация Calico](https://www.tigera.io/project-calico/).
2. [Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/).
3. [About Network Policy](https://docs.projectcalico.org/about/about-network-policy).

-----

### Задание 1. Создать сетевую политику или несколько политик для обеспечения доступа

1. Создать deployment'ы приложений frontend, backend и cache и соответсвующие сервисы.
2. В качестве образа использовать network-multitool.
3. Разместить поды в namespace App.
4. Создать политики, чтобы обеспечить доступ frontend -> backend -> cache. Другие виды подключений должны быть запрещены.
5. Продемонстрировать, что трафик разрешён и запрещён.

### Правила приёма работы

1. Домашняя работа оформляется в своём Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.

---

### Ответ

В качестве базы возьмем ноды из предыдущего задания, вместо flannel устанавливаем calico. Установку calico и calicoctl производим по инструкциям https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart и https://docs.tigera.io/calico/latest/operations/calicoctl/install

Скачиваем yaml конфиги calico (версия 3.27.0):

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
wget https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml
```

В файле [custom-resources.yaml](assets/custom-resources.yaml) меняем значение `cidr` на `172.16.0.0/20`, т.к. kubeadm инициировали с `--pod-network-cidr 172.16.0.0/20`:

Применяем calico манифесты:

```bash
kubectl create -f tigera-operator.yaml
kubectl create -f custom-resources.yaml
```

Далее скачиваем calicoctl:

```bash
curl -L https://github.com/projectcalico/calico/releases/download/v3.27.0/calicoctl-linux-amd64 -o calicoctl
chmod +x ./calicoctl
```

Берем ippool конфигурацию установленного calico:

```bash
ubuntu@vm-masternode:~$ calicoctl get ippool default-ipv4-ippool -o yaml > pool.yaml
```
В файле `pool.yaml` ставим значения `ipipMode: Always` и `vxlanMode: Never`. Применяем измененый конфиг через `calicoctl apply -f pool.yaml`.

В итоге получаем:

```bash
ubuntu@vm-masternode:~/deployments$ kubectl get pods -o wide -n calico-system
NAME                                      READY   STATUS    RESTARTS      AGE     IP              NODE            NOMINATED NODE   READINESS GATES
calico-kube-controllers-b5bd47ddd-gb7r6   1/1     Running   1 (23m ago)   5h25m   172.16.8.69     vm-masternode   <none>           <none>
calico-node-5sbbr                         1/1     Running   1 (23m ago)   5h25m   192.168.55.24   vm-node03       <none>           <none>
calico-node-656df                         1/1     Running   1 (23m ago)   5h25m   192.168.55.31   vm-node01       <none>           <none>
calico-node-rsfvl                         1/1     Running   1 (23m ago)   5h25m   192.168.55.10   vm-masternode   <none>           <none>
calico-node-srm8f                         1/1     Running   1 (23m ago)   5h25m   192.168.55.19   vm-node02       <none>           <none>
calico-typha-7f56847fdc-6kppv             1/1     Running   1 (23m ago)   5h25m   192.168.55.24   vm-node03       <none>           <none>
calico-typha-7f56847fdc-jrjbr             1/1     Running   1 (23m ago)   5h25m   192.168.55.31   vm-node01       <none>           <none>
csi-node-driver-5dbf7                     2/2     Running   2 (23m ago)   5h25m   172.16.0.69     vm-node02       <none>           <none>
csi-node-driver-8zch9                     2/2     Running   2 (23m ago)   5h25m   172.16.11.70    vm-node03       <none>           <none>
csi-node-driver-fsq78                     2/2     Running   2 (23m ago)   5h25m   172.16.2.196    vm-node01       <none>           <none>
csi-node-driver-t4l5h                     2/2     Running   2 (23m ago)   5h25m   172.16.8.72     vm-masternode   <none>           <none>
```

Далее создаем [namespace](assets/namespace.yaml), deployments и services для [backend](assets/backend.yaml), [cache](assets/cache.yaml) и [frontend](assets/frontend.yaml). Поды сделаем по два экземпляра.
Проверяем, что все поды и сервисы работают:

<details>
<summary> K8s initial state </summary>

```bash
ubuntu@vm-masternode:~$ kubectl get deployments -n app -o wide
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
netology-deployment-backend    2/2     2            2           22h   multitool    wbitt/network-multitool   app=app-back
netology-deployment-cache      2/2     2            2           22h   multitool    wbitt/network-multitool   app=app-cache
netology-deployment-frontend   2/2     2            2           22h   multitool    wbitt/network-multitool   app=app-front

ubuntu@vm-masternode:~$ kubectl get services -n app -o wide
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE   SELECTOR
svc-backend    ClusterIP   10.110.90.161    <none>        80/TCP    22h   app=app-back
svc-cache      ClusterIP   10.102.154.197   <none>        80/TCP    22h   app=app-cache
svc-frontend   ClusterIP   10.110.253.36    <none>        80/TCP    22h   app=app-front

ubuntu@vm-masternode:~$ kubectl get pods -n app -o wide
NAME                                           READY   STATUS    RESTARTS      AGE   IP             NODE        NOMINATED NODE   READINESS GATES
netology-deployment-backend-77555dd6cd-2k5d7   1/1     Running   2 (24m ago)   16h   172.16.0.80    vm-node02   <none>           <none>
netology-deployment-backend-77555dd6cd-5slw2   1/1     Running   3 (24m ago)   22h   172.16.11.76   vm-node03   <none>           <none>
netology-deployment-cache-58bf459b7-6strr      1/1     Running   3 (24m ago)   22h   172.16.11.77   vm-node03   <none>           <none>
netology-deployment-cache-58bf459b7-pcj7p      1/1     Running   2 (24m ago)   16h   172.16.2.207   vm-node01   <none>           <none>
netology-deployment-frontend-d9d8b8478-cmgk6   1/1     Running   2 (24m ago)   16h   172.16.2.206   vm-node01   <none>           <none>
netology-deployment-frontend-d9d8b8478-kn9kb   1/1     Running   3 (24m ago)   22h   172.16.0.81    vm-node02   <none>           <none>
```

</details>

Также добавим под [dnsutils](assets/dnsutils.yaml).\
Проверим, что вышеуказанные поды видят друг друга:

<details>
<summary> Checking pod connection </summary>

```bash
ubuntu@vm-masternode:~$ kubectl exec -n app -it netology-deployment-backend-77555dd6cd-2k5d7 -- curl svc-frontend
WBITT Network MultiTool (with NGINX) - netology-deployment-frontend-d9d8b8478-cmgk6 - 172.16.2.206 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
ubuntu@vm-masternode:~$ kubectl exec -n app -it netology-deployment-backend-77555dd6cd-2k5d7 -- curl svc-cache
WBITT Network MultiTool (with NGINX) - netology-deployment-cache-58bf459b7-6strr - 172.16.11.77 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
ubuntu@vm-masternode:~$ kubectl exec -n app -it netology-deployment-backend-77555dd6cd-2k5d7 -- curl svc-backend
WBITT Network MultiTool (with NGINX) - netology-deployment-backend-77555dd6cd-2k5d7 - 172.16.0.80 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```
```bash
ubuntu@vm-masternode:~$ kubectl exec -n app -it netology-deployment-cache-58bf459b7-6strr -- curl svc-backend
WBITT Network MultiTool (with NGINX) - netology-deployment-backend-77555dd6cd-2k5d7 - 172.16.0.80 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
ubuntu@vm-masternode:~$ kubectl exec -n app -it netology-deployment-cache-58bf459b7-6strr -- curl svc-cache
WBITT Network MultiTool (with NGINX) - netology-deployment-cache-58bf459b7-pcj7p - 172.16.2.207 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
ubuntu@vm-masternode:~$ kubectl exec -n app -it netology-deployment-cache-58bf459b7-6strr -- curl svc-frontend
WBITT Network MultiTool (with NGINX) - netology-deployment-frontend-d9d8b8478-cmgk6 - 172.16.2.206 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```

```bash
ubuntu@vm-masternode:~$ kubectl exec -n app -it netology-deployment-frontend-d9d8b8478-kn9kb -- curl svc-backend
WBITT Network MultiTool (with NGINX) - netology-deployment-backend-77555dd6cd-2k5d7 - 172.16.0.80 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
ubuntu@vm-masternode:~$ kubectl exec -n app -it netology-deployment-frontend-d9d8b8478-kn9kb -- curl svc-cache
WBITT Network MultiTool (with NGINX) - netology-deployment-cache-58bf459b7-6strr - 172.16.11.77 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
ubuntu@vm-masternode:~$ kubectl exec -n app -it netology-deployment-frontend-d9d8b8478-kn9kb -- curl svc-frontend
WBITT Network MultiTool (with NGINX) - netology-deployment-frontend-d9d8b8478-cmgk6 - 172.16.2.206 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```

</details>

Поды видят друг друга и все сервисы в namespace `app`.\
Применим политику [deny-all-ingress](assets/np-denyall.yaml) и проверим доступность сервисов на примере frontend пода:

```bash
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-frontend-d9d8b8478-kn9kb -- curl svc-frontend -m 10
curl: (28) Connection timed out after 10000 milliseconds
command terminated with exit code 28
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-frontend-d9d8b8478-kn9kb -- curl svc-backend -m 10
curl: (28) Connection timed out after 10000 milliseconds
command terminated with exit code 28
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-frontend-d9d8b8478-kn9kb -- curl svc-cache -m 10
curl: (28) Connection timed out after 10001 milliseconds
command terminated with exit code 28
```

Под не может подключиться ни к одному из сервисов.
Теперь создаем сетевые политики для наших приложений. Создаем политику [deny-all](assets/np-denyall.yaml) и отдельные политики доступа к подам для [frontend](assets/np-frontend.yaml), [backend](assets/np-backend.yaml) и [cache](assets/np-cache.yaml).

```bash
ubuntu@vm-masternode:~/deployment$ kubectl get networkpolicy -n app -o wide
NAME                  POD-SELECTOR    AGE
np-backend            app=app-back    13m
np-cache              app=app-cache   13m
np-deny-all           <none>          13m
np-frontend           app=app-front   13m
```

Проверяем доступность сервисов:

<details>
<summary> Checking pods after network policies</summary>
Frontend:

```bash
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-frontend-d9d8b8478-kn9kb -- curl svc-backend -m 5
WBITT Network MultiTool (with NGINX) - netology-deployment-backend-77555dd6cd-5slw2 - 172.16.11.76 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-frontend-d9d8b8478-kn9kb -- curl svc-frontend -m 5
curl: (28) Connection timed out after 5001 milliseconds
command terminated with exit code 28
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-frontend-d9d8b8478-kn9kb -- curl svc-cache -m 5
curl: (28) Connection timed out after 5000 milliseconds
command terminated with exit code 28
```

Backend:

```bash
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-backend-77555dd6cd-2k5d7 -- curl svc-frontend -m 5
curl: (28) Connection timed out after 5000 milliseconds
command terminated with exit code 28
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-backend-77555dd6cd-2k5d7 -- curl svc-backend -m 5
curl: (28) Connection timed out after 5000 milliseconds
command terminated with exit code 28
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-backend-77555dd6cd-2k5d7 -- curl svc-cache -m 5
WBITT Network MultiTool (with NGINX) - netology-deployment-cache-58bf459b7-pcj7p - 172.16.2.207 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
```

Cache:
```bash
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-cache-58bf459b7-6strr -- curl svc-frontend -m 5
curl: (28) Connection timed out after 5000 milliseconds
command terminated with exit code 28
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-cache-58bf459b7-6strr -- curl svc-backend -m 5
curl: (28) Connection timed out after 5001 milliseconds
command terminated with exit code 28
ubuntu@vm-masternode:~/deployments$ kubectl exec -n app -it netology-deployment-cache-58bf459b7-6strr -- curl svc-cache -m 5
curl: (28) Connection timed out after 5001 milliseconds
command terminated with exit code 28
```

</details>

---