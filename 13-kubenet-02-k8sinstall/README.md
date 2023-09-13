# Домашнее задание к занятию «Установка Kubernetes»

### Цель задания

Установить кластер K8s.

### Чеклист готовности к домашнему заданию

1. Развёрнутые ВМ с ОС Ubuntu 20.04-lts.


### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Инструкция по установке kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).
2. [Документация kubespray](https://kubespray.io/).

-----

### Задание 1. Установить кластер k8s с 1 master node

1. Подготовка работы кластера из 5 нод: 1 мастер и 4 рабочие ноды.
2. В качестве CRI — containerd.
3. Запуск etcd производить на мастере.
4. Способ установки выбрать самостоятельно.

### Ответ

Созадим VM с Ubuntu 20.04 в yandex cloud с hostname = `vm-masternode`, 2 CPU, 2 Gb RAM, 50 Gb HDD. Далее установим на VM `kubeadm` по [инструкции](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/).

Следующие итерации выполняются на всех нодах:

<details>
<summary>Setting up nodes</summary>

Отключаем swap, проверяем порт 6443:
```bash
sudo swapoff -a

nc 127.0.0.1 6443
```
Устанавливаем curl, ca-certificates, apt-transport-https:
```bash
sudo mkdir -p 0755 /etc/apt/keyrings
sudo apt update
sudo apt install apt-transport-https ca-certificates curl
```
Загружаем публичный ключ подписи для репозиториев пакетов Kubernetes и добавляем Kubernetes репозиторий:
```bash
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
Устанавливаем kubelet, kubeadm, kubectl. Закрепляем версии установленных пакетов:
```bash
sudo apt update
sudo apt install kubelet kubeadm kubectl containerd
sudo apt-mark hold kubelet kubeadm kubectl
```
Kubelet будет перезагружаться каждые несколько секунд, ожидая в аварийном цикле, пока kubeadm скажет ему, что делать.

Включаем forwarding (root пользователем)  следующими командами:

```bash
modprobe br_netfilter
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-arptables=1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables=1" >> /etc/sysctl.conf
echo 1 > /proc/sys/net/ipv4/ip_forward

root@vm-masternode:/home/ubuntu# sysctl -p /etc/sysctl.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
```

</details>

\
Kubeadm инициализация на мастер ноде:
```bash
ubuntu@node-master:~$ sudo kubeadm init \
--apiserver-advertise-address=192.168.150.3 \
--pod-network-cidr 10.244.0.0/16 \
--apiserver-cert-extra-sans=158.160.32.83
```

Ответом будет следующее:
<details>
<summary>Kubeadm init response</summary>

```bash
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.150.3:6443 --token <generated_token> --discovery-token-ca-cert-hash <cert_hash>
```

</details>

Необходимо убедиться, что порт на VM открыт:

```bash
sudo lsof -i -P -n | grep LISTEN
...
kube-apis 11229            root    3u  IPv6  72087      0t0  TCP *:6443 (LISTEN)
...
```

Скопируем kubeconfig для non-root пользователя:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Проверяем ноды:
```bash
ubuntu@vm-masternode:~$ kubectl get nodes
NAME            STATUS     ROLES           AGE   VERSION
vm-masternode   NotReady   control-plane   51m   v1.28.1
```

Устанавливаем плагин сети flannel:
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
Далее на мастер ноду устанавливаем etcd service по инструкции отсюда:
https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md

Снова проверям мастер ноду:

<details>
<summary>Check node</summary>

```bash
ubuntu@vm-masternode:~$ kubectl get nodes
NAME               STATUS   ROLES           AGE    VERSION
vm-masternode      Ready    control-plane   1d2h   v1.28.1

ubuntu@vm-masternode:~$ kubectl describe nodes vm-masternode
...
  Namespace                   Name                                     CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                                     ------------  ----------  ---------------  -------------  ---
  kube-flannel                kube-flannel-ds-sz726                    100m (5%)     0 (0%)      50Mi (2%)        0 (0%)         1d2h
  kube-system                 coredns-5dd5756b68-fd24n                 100m (5%)     0 (0%)      70Mi (3%)        170Mi (9%)     1d2h
  kube-system                 coredns-5dd5756b68-vhmgv                 100m (5%)     0 (0%)      70Mi (3%)        170Mi (9%)     1d2h
  kube-system                 etcd-vm-masternode                       100m (5%)     0 (0%)      100Mi (5%)       0 (0%)         1d2h
  kube-system                 kube-apiserver-vm-masternode             250m (12%)    0 (0%)      0 (0%)           0 (0%)         1d2h
  kube-system                 kube-controller-manager-vm-masternode    200m (10%)    0 (0%)      0 (0%)           0 (0%)         1d2h
  kube-system                 kube-proxy-v96ts                         0 (0%)        0 (0%)      0 (0%)           0 (0%)         1d2h
  kube-system                 kube-scheduler-vm-masternode             100m (5%)     0 (0%)      0 (0%)           0 (0%)         1d2h
...

```

</details>

\
На случай, если забыли `--token` и `--discovery-token-ca-cert-hash` для присоединения рабочих нод, генерируем их:
```bash
kubeadm token generate
kubeadm token create <generated_token> --print-join-command --ttl=0
```

Далее проделываем операции на рабочих нодах из описания сверху, а потом присоединяем ноды к кластеру:

```bash
sudo kubeadm join 192.168.150.3:6443 --token <generated_token> --discovery-token-ca-cert-hash <cert_hash>
```

В конце проверяем статус на мастер ноде:

```bash
ubuntu@vm-masternode:~$ kubectl get nodes
NAME               STATUS   ROLES           AGE    VERSION
vm-masternode      Ready    control-plane   2d7h   v1.28.1
vm-worker-node-1   Ready    <none>          2d8h   v1.28.1
vm-worker-node-2   Ready    <none>          71m    v1.28.1
vm-worker-node-3   Ready    <none>          53m    v1.28.1
vm-worker-node-4   Ready    <none>          19m    v1.28.1
```

## Дополнительные задания (со звёздочкой)

**Настоятельно рекомендуем выполнять все задания под звёздочкой.** Их выполнение поможет глубже разобраться в материале.   
Задания под звёздочкой необязательные к выполнению и не повлияют на получение зачёта по этому домашнему заданию. 

------
### Задание 2*. Установить HA кластер

1. Установить кластер в режиме HA.
2. Использовать нечётное количество Master-node.
3. Для cluster ip использовать keepalived или другой способ.

### Правила приёма работы

1. Домашняя работа оформляется в своем Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl get nodes`, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.