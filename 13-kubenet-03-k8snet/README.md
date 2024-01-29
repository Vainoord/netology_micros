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

В качестве базы возьмем ноды из предыдущего задания, вместо flannel устанавливаем calico. Установку calico производим по инструкции: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart

Скачиваем yaml конфиги calico:

```bash
wget https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
wget https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml
```

В файле [custom-resources.yaml](assets/custom-resources.yaml) меняем значение `cidr` на `10.244.0.0/16`, т.к. kubeadm инициировали с `--pod-network-cidr 10.244.0.0/16`:

```bash
sudo kubeadm init \
--apiserver-advertise-address=192.168.55.13 \
--pod-network-cidr 10.244.0.0/16 \
```

Применяем calico манифесты:

```bash
kubectl create -f tigera-operator.yaml
kubectl create -f custom-resources.yaml
```

В итоге получаем:

```bash
ubuntu@vm-masternode:~$ kubectl get pods -n calico-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-74fd6ff86b-ppknt   1/1     Running   0          5m42s
calico-node-hq7gb                          1/1     Running   0          5m42s
calico-typha-784b8b8f68-j4l7p              1/1     Running   0          5m42s
csi-node-driver-fgx24                      2/2     Running   0          5m42s

```

Далее создаем [namespace](assets/namespace.yaml), deployments и services для [backend](assets/backend.yaml), [cache](assets/cache.yaml) и [frontend](assets/frontend.yaml).
Проверяем, что они добавлены:

```bash
ubuntu@vm-masternode:~/deployment$ kubectl get deployments -n app -o wide
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
netology-deployment-backend    1/1     1            1           25s   multitool    wbitt/network-multitool   app=app-back
netology-deployment-cache      1/1     1            1           20s   multitool    wbitt/network-multitool   app=app-cache
netology-deployment-frontend   1/1     1            1           17s   multitool    wbitt/network-multitool   app=app-front

ubuntu@vm-masternode:~/deployment$ kubectl get services -n app -o wide
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
svc-backend    ClusterIP   10.107.86.231   <none>        80/TCP    8d    app=app-back
svc-cache      ClusterIP   10.101.26.247   <none>        80/TCP    8d    app=app-cache
svc-frontend   ClusterIP   10.102.159.87   <none>        80/TCP    8d    app=app-front

ubuntu@vm-masternode:~/deployment$ kubectl get pods -n app -o wide
NAME                                           READY   STATUS    RESTARTS       AGE   IP               NODE        NOMINATED NODE   READINESS GATES
netology-deployment-backend-77555dd6cd-kfcvd   1/1     Running   3 (105m ago)   8d    10.244.183.82    vm-node03   <none>           <none>
netology-deployment-cache-58bf459b7-dqgd2      1/1     Running   3 (104m ago)   8d    10.244.188.75    vm-node01   <none>           <none>
netology-deployment-frontend-d9d8b8478-pcd54   1/1     Running   3 (105m ago)   8d    10.244.187.145   vm-node02   <none>           <none>
```

Проверим, что из подов видны все сервисы. Применим политику [allow-all-ingress](assets/np-allowall.yaml) и проверим доступность сервисов:

```bash
ubuntu@vm-masternode:~/deployment$ kubectl get networkpolicy -A
NAMESPACE          NAME                POD-SELECTOR     AGE
app                allow-all-ingress   <none>           34m
calico-apiserver   allow-apiserver     apiserver=true   16d
```

```bash
ubuntu@vm-masternode:~/deployment$ kubectl exec -it -n app netology-deployment-cache-58bf459b7-dqgd2 -- curl 10.101.26.247:80
WBITT Network MultiTool (with NGINX) - netology-deployment-cache-58bf459b7-dqgd2 - 10.244.188.75 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)

ubuntu@vm-masternode:~/deployment$ kubectl exec -it -n app netology-deployment-cache-58bf459b7-dqgd2 -- curl 10.102.159.87:80
curl: (28) Failed to connect to 10.102.159.87 port 80 after 129406 ms: Couldn't connect to server
command terminated with exit code 28

ubuntu@vm-masternode:~/deployment$ kubectl exec -it -n app netology-deployment-cache-58bf459b7-dqgd2 -- curl 10.102.86.231:80
curl: (28) Failed to connect to 10.102.86.231 port 80 after 129513 ms: Couldn't connect to server
command terminated with exit code 28
```

Видим, что под может подключиться к своему сервису, но не имеет доступа к другим сервисам. Тажке не работает curl с DNS именем сервисов:

```bash
ubuntu@vm-masternode:~/deployment$ kubectl exec -it -n app netology-deployment-cache-58bf459b7-dqgd2 -- curl svc-cache
curl: (6) Could not resolve host: svc-cache
command terminated with exit code 6

ubuntu@vm-masternode:~/deployment$ kubectl exec -it -n app netology-deployment-cache-58bf459b7-dqgd2 -- curl svc-frontend
curl: (6) Could not resolve host: svc-frontend
command terminated with exit code 6

ubuntu@vm-masternode:~/deployment$ kubectl exec -it -n app netology-deployment-cache-58bf459b7-dqgd2 -- curl svc-backend
curl: (6) Could not resolve host: svc-backend
command terminated with exit code 6
```

Конфиг [coredns](assets/coredns.yaml) прилагаю.

---

<details>
<summary> network policies block</summary>
Теперь создаем сетевые политики для наших приложений. Создаем политику [deny-all](assets/np-denyall.yaml) и отдельные политики доступа к подам для [frontend](assets/np-frontend.yaml), [backend](assets/np-backend.yaml) и [cache](assets/np-cache.yaml).

```bash

ubuntu@vm-masternode:~/deployment$ kubectl get networkpolicy -n app -o wide
NAME                  POD-SELECTOR    AGE
np-backend            app=app-back    13m
np-cache              app=app-cache   13m
np-deny-all           <none>          13m
np-frontend           app=app-front   13m

```

</details>
