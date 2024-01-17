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

В файле `custom-resources.yaml` меняем значение `cidr` на `10.244.0.0/16`, т.к. kubeadm инициировали с `--pod-network-cidr 10.244.0.0/16`.

Применяем :

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
NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE   SELECTOR
frontend-service        ClusterIP   10.102.249.144   <none>        80/TCP     50s   app=app-front
netology-service-back   ClusterIP   10.109.14.52     <none>        8080/TCP   58s   app=app-back
netology-svc-cache      ClusterIP   10.98.68.235     <none>        8090/TCP   53s   app=app-cache

ubuntu@vm-masternode:~/deployment$ kubectl get pods -n app -o wide
NAME                                            READY   STATUS    RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
netology-deployment-backend-66cf76d8b-269bk     1/1     Running   0          80s   10.244.187.133   vm-node02   <none>           <none>
netology-deployment-cache-57478cb969-p84q9      1/1     Running   0          75s   10.244.188.68    vm-node01   <none>           <none>
netology-deployment-frontend-5489899c8b-bwmnx   1/1     Running   0          72s   10.244.187.134   vm-node02   <none>           <none>
```

Теперь создаем сетевые политики для наших приложений. Создаем политику [deny-all](assets/np-denyall.yaml) и отдельные политики доступа к подам для [frontend](assets/np-frontend.yaml), [backend](assets/np-backend.yaml) и [cache](assets/np-cache.yaml).

```bash

ubuntu@vm-masternode:~/deployment$ kubectl get networkpolicy -n app -o wide
NAME                  POD-SELECTOR    AGE
np-backend            app=app-back    13m
np-backend-to-cache   app=app-cache   13m
np-deny-all           <none>          13m
np-frontend           app=app-front   13m

```

```bash
ubuntu@vm-masternode:~/deployment$ kubectl exec -it netology-deployment-frontend-5489899c8b-bwmnx -n app -c multitool -- /bin/bash
```

sudo kubeadm join 192.168.55.13:6443 --token 5z2srv.vuqsdaq5dk2uj6jo \
--discovery-token-ca-cert-hash sha256:5b47de47c90ecc55e1c699fb7a1e4ab5e9d636e639ec4aa9066e55edf8d7fdb5