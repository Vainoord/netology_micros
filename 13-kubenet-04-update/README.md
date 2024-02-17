# Домашнее задание к занятию «Обновление приложений»

### Цель задания

Выбрать и настроить стратегию обновления приложения.

### Чеклист готовности к домашнему заданию

1. Кластер K8s.

### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Документация Updating a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment).
2. [Статья про стратегии обновлений](https://habr.com/ru/companies/flant/articles/471620/).

-----

### Задание 1. Выбрать стратегию обновления приложения и описать ваш выбор

1. Имеется приложение, состоящее из нескольких реплик, которое требуется обновить.
2. Ресурсы, выделенные для приложения, ограничены, и нет возможности их увеличить.
3. Запас по ресурсам в менее загруженный момент времени составляет 20%.
4. Обновление мажорное, новые версии приложения не умеют работать со старыми.
5. Вам нужно объяснить свой выбор стратегии обновления приложения.

### Задание 2. Обновить приложение

1. Создать deployment приложения с контейнерами nginx и multitool. Версию nginx взять 1.19. Количество реплик — 5.
2. Обновить версию nginx в приложении до версии 1.20, сократив время обновления до минимума. Приложение должно быть доступно.
3. Попытаться обновить nginx до версии 1.28, приложение должно оставаться доступным.
4. Откатиться после неудачного обновления.

## Дополнительные задания — со звёздочкой*

Задания дополнительные, необязательные к выполнению, они не повлияют на получение зачёта по домашнему заданию. **Но мы настоятельно рекомендуем вам выполнять все задания со звёздочкой.** Это поможет лучше разобраться в материале.   

### Задание 3*. Создать Canary deployment

1. Создать два deployment'а приложения nginx.
2. При помощи разных ConfigMap сделать две версии приложения — веб-страницы.
3. С помощью ingress создать канареечный деплоймент, чтобы можно было часть трафика перебросить на разные версии приложения.

### Правила приёма работы

1. Домашняя работа оформляется в своем Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.

---

### Ответы

#### Задание 1.
Если новая версия не совместима в работе со старой, то можно применить `Recreate`, в таком случае во время обновления приложение будет недоступно. В случае ошибок работы обновленного приложения можно вернуть старые поды разом.

Можно выбрать другой способ - политику обновлению `Rolling Update`. В случае, если <=20% оставшихся ресурсов позволяют создать хотя бы один под, то подойдет следующая конфигурация: 

```yaml
...
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
...
```

В таком случае обновление будет происходит по одному поду за раз, при этом под с обновленной версией приложения будет создан до удаления пода со старой версией. В случае ошибок на новом поде дальнейшее обновление прекратится. Неудачное обновление такэе можно будет откатить и вернуться к предыдущей версии пода.

---

#### Задание 2.

Сначала поднимем 5 подов с nginx 1.19. Создаем [namespace](assets/namespace.yaml) и [nginx-toolbox поды](assets/nginx_119.yaml).

Проверим статус подов, деплоймента и версию nginx:

```bash
ubuntu@vm-masternode:~$ kubectl get pods -n nginx-app -o wide
NAME                                       READY   STATUS    RESTARTS   AGE   IP             NODE            NOMINATED NODE   READINESS GATES
nginx-multitool-backend-75b9dd4598-5tmzb   2/2     Running   0          23s   172.16.2.217   vm-node01       <none>           <none>
nginx-multitool-backend-75b9dd4598-fcwp9   2/2     Running   0          23s   172.16.11.88   vm-node03       <none>           <none>
nginx-multitool-backend-75b9dd4598-mkcrd   2/2     Running   0          23s   172.16.0.90    vm-node02       <none>           <none>
nginx-multitool-backend-75b9dd4598-mpnw5   2/2     Running   0          23s   172.16.8.91    vm-masternode   <none>           <none>
nginx-multitool-backend-75b9dd4598-ncbdr   2/2     Running   0          23s   172.16.11.89   vm-node03       <none>           <none>

ubuntu@vm-masternode:~$ kubectl get deployments.apps -n nginx-app
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
nginx-multitool-backend   5/5     5            5           105s

ubuntu@vm-masternode:~$ kubectl exec -n nginx-app -it nginx-multitool-backend-75b9dd4598-ncbdr -c nginx -- /usr/sbin/nginx -v
nginx version: nginx/1.19.10
```
Далее создадим манифест с версией nginx [1.20](assets/nginx_120.yaml), применим его.

Наблюдаем процесс обновления:

<details>
<summary> kubectl get pods -w -n nginx-app</summary>

```bash

ubuntu@vm-masternode:~$ kubectl get pods -n nginx-app -w 
NAME                                       READY   STATUS              RESTARTS   AGE
nginx-multitool-backend-75b9dd4598-mpnw5   2/2     Running             0          13m
nginx-multitool-backend-75b9dd4598-ncbdr   2/2     Running             0          13m
nginx-multitool-backend-784475c6b6-6t7jq   2/2     Running             0          17s
nginx-multitool-backend-784475c6b6-l2chd   0/2     ContainerCreating   0          8s
nginx-multitool-backend-784475c6b6-njcgt   2/2     Running             0          17s
nginx-multitool-backend-784475c6b6-sm79f   0/2     ContainerCreating   0          5s
nginx-multitool-backend-784475c6b6-l2chd   2/2     Running             0          10s
nginx-multitool-backend-75b9dd4598-mpnw5   2/2     Terminating         0          14m
nginx-multitool-backend-784475c6b6-2m7hm   0/2     Pending             0          0s
nginx-multitool-backend-784475c6b6-2m7hm   0/2     Pending             0          0s
nginx-multitool-backend-784475c6b6-2m7hm   0/2     ContainerCreating   0          1s
nginx-multitool-backend-784475c6b6-2m7hm   0/2     ContainerCreating   0          3s
nginx-multitool-backend-75b9dd4598-mpnw5   2/2     Terminating         0          14m
nginx-multitool-backend-784475c6b6-2m7hm   2/2     Running             0          3s
nginx-multitool-backend-75b9dd4598-ncbdr   2/2     Terminating         0          14m
nginx-multitool-backend-75b9dd4598-mpnw5   0/2     Terminating         0          14m
nginx-multitool-backend-75b9dd4598-mpnw5   0/2     Terminating         0          14m
nginx-multitool-backend-75b9dd4598-mpnw5   0/2     Terminating         0          14m
nginx-multitool-backend-75b9dd4598-mpnw5   0/2     Terminating         0          14m
nginx-multitool-backend-75b9dd4598-ncbdr   2/2     Terminating         0          14m
nginx-multitool-backend-75b9dd4598-ncbdr   0/2     Terminating         0          14m
nginx-multitool-backend-784475c6b6-sm79f   2/2     Running             0          11s
nginx-multitool-backend-75b9dd4598-ncbdr   0/2     Terminating         0          14m
nginx-multitool-backend-75b9dd4598-ncbdr   0/2     Terminating         0          14m
nginx-multitool-backend-75b9dd4598-ncbdr   0/2     Terminating         0          14m

```

</details>

Проверим статус подов, деплоймента и версию nginx после некоторого времени:

```bash
ubuntu@vm-masternode:~$ kubectl get pods -n nginx-app -o wide
NAME                                       READY   STATUS    RESTARTS   AGE     IP             NODE            NOMINATED NODE   READINESS GATES
nginx-multitool-backend-784475c6b6-2m7hm   2/2     Running   0          2m55s   172.16.0.92    vm-node02       <none>           <none>
nginx-multitool-backend-784475c6b6-6t7jq   2/2     Running   0          3m14s   172.16.2.218   vm-node01       <none>           <none>
nginx-multitool-backend-784475c6b6-l2chd   2/2     Running   0          3m5s    172.16.11.90   vm-node03       <none>           <none>
nginx-multitool-backend-784475c6b6-njcgt   2/2     Running   0          3m14s   172.16.0.91    vm-node02       <none>           <none>
nginx-multitool-backend-784475c6b6-sm79f   2/2     Running   0          3m2s    172.16.8.92    vm-masternode   <none>           <none>

ubuntu@vm-masternode:~$ kubectl get deployments.apps -n nginx-app
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
nginx-multitool-backend   5/5     5            5           18m

ubuntu@vm-masternode:~$ kubectl exec -n nginx-app -it nginx-multitool-backend-784475c6b6-sm79f -c nginx -- /usr/sbin/nginx -v
nginx version: nginx/1.20.2
```

Также можно проверить историю обновлений деплоймента:

```bash
ubuntu@vm-masternode:~$ kubectl rollout history deployment.apps/nginx-multitool-backend -n nginx-app
deployment.apps/nginx-multitool-backend 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

ubuntu@vm-masternode:~$ kubectl get rs -n nginx-app -o wide
NAME                                 DESIRED   CURRENT   READY   AGE   CONTAINERS        IMAGES                               SELECTOR
nginx-multitool-backend-75b9dd4598   0         0         0       25m   nginx,multitool   nginx:1.19,wbitt/network-multitool   app=nginx-multitool,pod-template-hash=75b9dd4598
nginx-multitool-backend-784475c6b6   5         5         5       11m   nginx,multitool   nginx:1.20,wbitt/network-multitool   app=nginx-multitool,pod-template-hash=784475c6b6
```

Далее попытаемся обновить nginx до версии [1.28](assets/nginx_128.yaml). В процессе видим следующее:

<details>
<summary>Checking pods update</summary>

```bash
ubuntu@vm-masternode:~$ kubectl get pods -w -n nginx-app
NAME                                       READY   STATUS             RESTARTS   AGE
nginx-multitool-backend-7545fc9954-4dgzq   1/2     ImagePullBackOff   0          27s
nginx-multitool-backend-7545fc9954-5kctr   1/2     ErrImagePull       0          27s
nginx-multitool-backend-784475c6b6-6t7jq   2/2     Running            0          20m
nginx-multitool-backend-784475c6b6-l2chd   2/2     Running            0          20m
nginx-multitool-backend-784475c6b6-njcgt   2/2     Running            0          20m
nginx-multitool-backend-784475c6b6-sm79f   2/2     Running            0          20m
nginx-multitool-backend-7545fc9954-4dgzq   1/2     ErrImagePull       0          32s
nginx-multitool-backend-7545fc9954-5kctr   1/2     ImagePullBackOff   0          40s
```

</details>

Только 20% подов может быть задействовано в обновлении одновременно согласно манифесту. Текущее состояние обновления:

```bash
ubuntu@vm-masternode:~$ kubectl rollout history deployment.apps/nginx-multitool-backend -n nginx-app
deployment.apps/nginx-multitool-backend 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>

ubuntu@vm-masternode:~$ kubectl get rs -n nginx-app -o wide
NAME                                 DESIRED   CURRENT   READY   AGE     CONTAINERS        IMAGES                               SELECTOR
nginx-multitool-backend-7545fc9954   2         2         0       5m15s   nginx,multitool   nginx:1.28,wbitt/network-multitool   app=nginx-multitool,pod-template-hash=7545fc9954
nginx-multitool-backend-75b9dd4598   0         0         0       39m     nginx,multitool   nginx:1.19,wbitt/network-multitool   app=nginx-multitool,pod-template-hash=75b9dd4598
nginx-multitool-backend-784475c6b6   4         4         4       25m     nginx,multitool   nginx:1.20,wbitt/network-multitool   app=nginx-multitool,pod-template-hash=784475c6b6
```

Обновление nginx до 1.28 не выполнено. Приложение остается доступным, 1/5 подов с ошибкой: под с версией 1.20 был ликвидирован и замена для него не запустилась. Задвоение подов в get команде из-за параметра `revisionHistoryLimit: 10`.

Откатим последнее обновление.

```bash
ubuntu@vm-masternode:~$ kubectl rollout undo deployment.apps/nginx-multitool-backend -n nginx-app
deployment.apps/nginx-multitool-backend rolled back
```

Проверяем состояние деплоймента после некоторого времени:

```bash
ubuntu@vm-masternode:~$ kubectl get pods -n nginx-app
NAME                                       READY   STATUS    RESTARTS   AGE
nginx-multitool-backend-784475c6b6-6t7jq   2/2     Running   0          35m
nginx-multitool-backend-784475c6b6-l2chd   2/2     Running   0          35m
nginx-multitool-backend-784475c6b6-njcgt   2/2     Running   0          35m
nginx-multitool-backend-784475c6b6-qtt9x   2/2     Running   0          82s
nginx-multitool-backend-784475c6b6-sm79f   2/2     Running   0          35m

ubuntu@vm-masternode:~$ kubectl rollout history deployment.apps/nginx-multitool-backend -n nginx-app
deployment.apps/nginx-multitool-backend 
REVISION  CHANGE-CAUSE
1         <none>
3         <none>
4         <none>

ubuntu@vm-masternode:~$ kubectl get rs -n nginx-app -o wide
NAME                                 DESIRED   CURRENT   READY   AGE   CONTAINERS        IMAGES                               SELECTOR
nginx-multitool-backend-7545fc9954   0         0         0       16m   nginx,multitool   nginx:1.28,wbitt/network-multitool   app=nginx-multitool,pod-template-hash=7545fc9954
nginx-multitool-backend-75b9dd4598   0         0         0       49m   nginx,multitool   nginx:1.19,wbitt/network-multitool   app=nginx-multitool,pod-template-hash=75b9dd4598
nginx-multitool-backend-784475c6b6   5         5         5       36m   nginx,multitool   nginx:1.20,wbitt/network-multitool   app=nginx-multitool,pod-template-hash=784475c6b6
```

Поды запущены с версией nginx 1.20. Все поды запущены, тещушая версия rollout теперь 4, она же была 2.
---