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

---

### Ответ

В качестве базы возьмем ноды из предыдущего задания без модуля flannel. Установку calico производим по инструкции: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart

Используем следущий набор команд на masternode:

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/tigera-operator.yaml
wget https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/custom-resources.yaml
```

В файле `custom-resources.yaml` меняем значение `cidr` на 10.244.0.0/16, т.к. kubeadm инициировали с `--pod-network-cidr 10.244.0.0/16`.

Далее:

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/custom-resources.yaml
```

В итоге получаем:

```bash
ubuntu@node-control:~$ kubectl get pods -n calico-system
NAME                                       READY   STATUS    RESTARTS       AGE
calico-kube-controllers-7d69f5d69c-h27cs   1/1     Running   1 (19s ago)    2m49s
calico-node-ckklk                          0/1     Running   2 (74s ago)    2m49s
calico-node-khs75                          1/1     Running   0              2m49s
calico-node-lgtqg                          0/1     Running   1 (19s ago)    2m49s
calico-node-tx6xd                          1/1     Running   0              2m49s
calico-typha-55b96cd744-m6ss8              1/1     Running   2 (41s ago)    2m42s
calico-typha-55b96cd744-vfzft              1/1     Running   1 (92s ago)    2m50s
csi-node-driver-2gv8k                      2/2     Running   0              2m49s
csi-node-driver-krkv8                      2/2     Running   2 (106s ago)   2m49s
csi-node-driver-t8kt6                      2/2     Running   0              2m49s
csi-node-driver-zbcvx                      2/2     Running   0              2m49s

ubuntu@node-control:~$ kubectl get nodes -o wide
The connection to the server 192.168.55.21:6443 was refused - did you specify the right host or port?
```

<u>В последующем с каждой командой kubectl получаем ответ "The connection to the server 192.168.55.21:6443 was refused - did you specify the right host or port?".
</u>

### Правила приёма работы

1. Домашняя работа оформляется в своём Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.
