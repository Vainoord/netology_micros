# Домашнее задание к занятию Troubleshooting

### Цель задания

Устранить неисправности при деплое приложения.

### Чеклист готовности к домашнему заданию

1. Кластер K8s.

### Задание. При деплое приложение web-consumer не может подключиться к auth-db. Необходимо это исправить

1. Установить приложение по команде:
```shell
kubectl apply -f https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml
```
2. Выявить проблему и описать.
3. Исправить проблему, описать, что сделано.
4. Продемонстрировать, что проблема решена.


### Правила приёма работы

1. Домашняя работа оформляется в своём Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.

---

### Ответ

Скачаем и применим манифест:

```bash
ubuntu@vm-masternode:~/deployments-5$ wget https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml
--2024-02-19 14:11:52--  https://raw.githubusercontent.com/netology-code/kuber-homeworks/main/3.5/files/task.yaml
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 185.199.110.133, 185.199.111.133, 185.199.108.133, ...
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|185.199.110.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 937 [text/plain]
Saving to: ‘task.yaml’

task.yaml                                   100%[========================================================================================>]     937  --.-KB/s    in 0s      

2024-02-19 14:11:53 (72.8 MB/s) - ‘task.yaml’ saved [937/937]


ubuntu@vm-masternode:~/deployments-5$ kubectl apply -f task.yaml 
Error from server (NotFound): error when creating "task.yaml": namespaces "web" not found
Error from server (NotFound): error when creating "task.yaml": namespaces "data" not found
Error from server (NotFound): error when creating "task.yaml": namespaces "data" not found
```

Нехватает двух `namespaces`: web и data. Создадим манифест [namespaces](assets/namespaces.yaml), применим манифесты:\

<details>
<summary>Adding namespaces</summary>

```bash
ubuntu@vm-masternode:~/deployments-5$ kubectl apply -f namespaces.yaml
namespace/web created
namespace/data created


ubuntu@vm-masternode:~/deployments-5$ kubectl apply -f task.yaml 
deployment.apps/web-consumer created
deployment.apps/auth-db created
service/auth-db created


ubuntu@vm-masternode:~/deployments-5$ kubectl get pods -o wide -n web
NAME                            READY   STATUS    RESTARTS   AGE    IP             NODE        NOMINATED NODE   READINESS GATES
web-consumer-5f87765478-56rh2   1/1     Running   0          4m3s   172.16.11.99   vm-node03   <none>           <none>
web-consumer-5f87765478-v89tr   1/1     Running   0          4m3s   172.16.0.101   vm-node02   <none>           <none>
ubuntu@vm-masternode:~/deployments-5$ kubectl get pods -o wide -n data
NAME                       READY   STATUS    RESTARTS   AGE    IP             NODE        NOMINATED NODE   READINESS GATES
auth-db-7b5cdbdc77-cp9dp   1/1     Running   0          4m6s   172.16.2.226   vm-node01   <none>           <none>
```

</details>

Поды добавлены. Проверим логи:

<details>
<summary> Logs summary </summary>

```bash
ubuntu@vm-masternode:~/deployments-5$ kubectl logs auth-db-7b5cdbdc77-cp9dp -n data
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
```

```bash
ubuntu@vm-masternode:~/deployments-5$ kubectl logs web-consumer-5f87765478-56rh2 -n web
curl: (6) Couldn't resolve host 'auth-db'
curl: (6) Couldn't resolve host 'auth-db'
curl: (6) Couldn't resolve host 'auth-db'
curl: (6) Couldn't resolve host 'auth-db'
curl: (6) Couldn't resolve host 'auth-db'
```

</details>

С `auth-db` проблем в логах нет. Но `web` приложения не могу подключиться к `auth-db` по dns имени хоста. Проверим работу nginx через `curl auth-db` на поде `auth-db`:

```bash
ubuntu@vm-masternode:~/deployments-5$ kubectl exec -it -n data auth-db-7b5cdbdc77-cp9dp -- curl auth-db
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
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

Nginx работает.\
Тогда попробуем сделать curl на подес указанием имени сервиса и имени namespace, как `auth-db.data`:

```bash
ubuntu@vm-masternode:~/deployments-5$ kubectl exec -it -n web web-consumer-5f87765478-56rh2 -- curl auth-db
curl: (6) Couldn't resolve host 'auth-db'
command terminated with exit code 6

ubuntu@vm-masternode:~/deployments-5$ kubectl exec -it -n web web-consumer-5f87765478-56rh2 -- curl auth-db.data
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
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

Поменяем в исходном манифесте строку `- while true; do curl auth-db; sleep 5; done` на `- while true; do curl auth-db.data; sleep 5; done`. Применим обновления и проверим.

<details>
<summary> Manifest update </summary>

```bash
ubuntu@vm-masternode:~/deployments-5$ kubectl apply -f task.yaml 
deployment.apps/web-consumer configured
deployment.apps/auth-db unchanged
service/auth-db unchanged


ubuntu@vm-masternode:~/deployments-5$ kubectl logs web-consumer-76669b5d6d-9kc6s -n web
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   612  100   612    0     0   139k      0 --:--:-- --:--:-- --:--:--  597k
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
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
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
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
100   612  100   612    0     0   219k      0 --:--:-- --:--:-- --:--:--  597k
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   612  100   612    0     0   147k      0 --:--:-- --:--:-- --:--:--  597k
<!DOCTYPE html>
<html>

...
```

</details>

Все работает.\
Итого необходимо добавить два namespace в манифест и обновить исполняемый shell код в busyboxplus контейнере - добавить имя namespace к имени сервиса. Итоговый манифест выглядит примерно [так](assets/final_manifest.yaml).

---