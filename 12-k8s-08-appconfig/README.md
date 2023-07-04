# Домашнее задание к занятию «Конфигурация приложений»

### Цель задания

В тестовой среде Kubernetes необходимо создать конфигурацию и продемонстрировать работу приложения.

------

### Чеклист готовности к домашнему заданию

1. Установленное K8s-решение (например, MicroK8s).
2. Установленный локальный kubectl.
3. Редактор YAML-файлов с подключённым GitHub-репозиторием.

------

### Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Описание](https://kubernetes.io/docs/concepts/configuration/secret/) Secret.
2. [Описание](https://kubernetes.io/docs/concepts/configuration/configmap/) ConfigMap.
3. [Описание](https://github.com/wbitt/Network-MultiTool) Multitool.

------

### Задание 1. Создать Deployment приложения и решить возникшую проблему с помощью ConfigMap. Добавить веб-страницу

1. Создать Deployment приложения, состоящего из контейнеров busybox и multitool.
2. Решить возникшую проблему с помощью ConfigMap.
3. Продемонстрировать, что pod стартовал и оба конейнера работают.
4. Сделать простую веб-страницу и подключить её к Nginx с помощью ConfigMap. Подключить Service и показать вывод curl или в браузере.
5. Предоставить манифесты, а также скриншоты или вывод необходимых команд.

### Ответ

Создадим `Deployment` с busybox и multitool:

<details>
<summary>Initial deployment manifest</summary>

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  namespace: ns-homework
  labels:
    app: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
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
        command: ['sh', '-c', "sleep 10; while true; do ping -c 3 google.com; sleep 5; done"]
      - name: multitool
        image: wbitt/network-multitool:latest
        resources:
          requests:
            memory: "64Mi"
            cpu: "125m"
          limits:
            memory: "128Mi"
            cpu: "250m"
```
</details>

\
После подключения `Deployment` поды работают, конфликтов не обнаружено:

```shell
ubuntu@ubuntu-mk8s:~$ microk8s kubectl get deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
myapp-deployment   1/1     1            1           8m59s

ubuntu@ubuntu-mk8s:~$ microk8s kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
myapp-deployment-58c976554b-npxd5   2/2     Running   0          9m4s
```

Теперь сделаем простенькую web-страницу и подключим ее к Nginx. При этом  добавим новый контейнер с Nginx к существующему `Deployment` и создадим `Service` для подключения к Nginx. Также сделаем два `ConfigMap` для multitool с описанием портов (разрешаем возможные конфликты портов с экземпляром Nginx), а для Nginx - с web-страницей:

<details>
<summary>ConfigMap manifest</summary>

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-deployment
  namespace: ns-homework
data:
  multitool-port-http: "8081"
  multitool-port-https: "8444"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-html
  namespace: ns-homework
data:
  index.html: |
    <!DOCTYPE html>
    <html>
      <head>
        <title>Hello world!</title>
      </head>
      <body>
        <h1>This page hosted in my nginx pod.</h1>
      </body>
    </html>
```

</details>
<details>
<summary>Service manifest</summary>

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: srv-nginx
  namespace: ns-homework
spec:
  selector:
    app: myapp
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  type: NodePort
```

</details>

<details>
<summary>Updating deployment</summary>

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  namespace: ns-homework
  labels:
    app: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      # Busybox container
      - name: busybox
        image: busybox:stable
        resources:
          requests:
            memory: "64Mi"
            cpu: "125m"
          limits:
            memory: "128Mi"
            cpu: "250m"
        command: ['sh', '-c', "sleep 10; while true; do ping -c 3 google.com; sleep 5; done"]
      # Multitool container
      - name: multitool
        image: wbitt/network-multitool:latest
        resources:
          requests:
            memory: "64Mi"
            cpu: "125m"
          limits:
            memory: "128Mi"
            cpu: "250m"
        # Getting http/https ports from configmap
        # Attaching configmap via ENV
        env:
          - name: HTTP_PORT
            valueFrom:
              configMapKeyRef:
                name: configmap-deployment
                key: multitool-port-http
          - name: HTTPS_PORT
            valueFrom:
              configMapKeyRef:
                name: configmap-deployment
                key: multitool-port-https
        ports:
        - containerPort: 8081
        - containerPort: 8444
      # Nginx container
      - name: nginx
        image: nginx:1.23.4
        resources:
          requests:
            memory: "64Mi"
            cpu: "125m"
          limits:
            memory: "128Mi"
            cpu: "250m"
        # Attaching nginx configmap via VOLUME
        volumeMounts:
          - mountPath: /usr/share/nginx/html
            name: html            
        ports:
        - containerPort: 80
      volumes:
      - name: html
        configMap:
          name: configmap-html
```

</details>

\
Проверяем статус `Deployment`, `Service`, `ConfigMaps`:

<details>
<summary>Status</summary>

```shell
ubuntu@ubuntu-mk8s:~$ microk8s kubectl get service
NAME        TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
srv-nginx   NodePort   10.152.183.222   <none>        80:31439/TCP   42m

ubuntu@ubuntu-mk8s:~$ microk8s kubectl get deployment
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
myapp-deployment   1/1     1            1           66m

ubuntu@ubuntu-mk8s:~$ microk8s kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
myapp-deployment-57679b9d64-5mnxj   3/3     Running   0          15m

ubuntu@ubuntu-mk8s:~$ microk8s kubectl get configmaps
NAME                   DATA   AGE
kube-root-ca.crt       1      42d
configmap-deployment   2      41m
configmap-html         1      41m
```
</details>

\
Проверим доступ к нашей web-странице через `Service`:

```shell
ubuntu@ubuntu-mk8s:~$ curl http://srv-nginx:80
<!DOCTYPE html>
<html>
  <head>
    <title>Hello world!</title>
  </head>
  <body>
    <h1>This page hosted in my nginx pod.</h1>
  </body>
</html>

```
------

### Задание 2. Создать приложение с вашей веб-страницей, доступной по HTTPS 

1. Создать Deployment приложения, состоящего из Nginx.
2. Создать собственную веб-страницу и подключить её как ConfigMap к приложению.
3. Выпустить самоподписной сертификат SSL. Создать Secret для использования сертификата.
4. Создать Ingress и необходимый Service, подключить к нему SSL в вид. Продемонстировать доступ к приложению по HTTPS. 
4. Предоставить манифесты, а также скриншоты или вывод необходимых команд.

### Ответ

Для начала сгенерируем самоподписанный сертификат:

```shell
openssl x509 -signkey tls.key -in tls.csr -req -days 365 -out tls.crt
openssl x509 -req -in tls.csr -signkey tls.key -out tls.crt
```
Далее создадим `Secret` через консоль:

```shell
vainoord@vnrd-mypc infrastructure $ kubectl create secret tls secret-nginx --cert=./tls.crt --key=./tls.key
secret/secret-nginx created

vainoord@vnrd-mypc infrastructure $ kubectl get secret                                                     
NAME           TYPE                DATA   AGE
secret-nginx   kubernetes.io/tls   2      1m
```

После добавим `Configmap` с тестовой страницой и конфигурацией nginx. Сертификат закинем в контейнер в `/etc/nginx/ssl/`, html страницу в `/usr/share/nginx/html`:

<details>
<summary>ConfigMap manifest</summary>

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-html
  namespace: ns-homework
data:
  index.html: |
    <!DOCTYPE html>
    <html>
      <head>
        <title>Hello world!</title>
      </head>
      <body>
        <h1>This page hosted in my nginx pod.</h1>
      </body>
    </html>
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-nginx
  namespace: ns-homework
data:
  default.conf: |
    server {
        listen 80;
        listen [::]:80;
        listen 443 ssl;

        location / {
            root /usr/share/nginx/html;
            index index.html;
        }

        server_name localhost;
        ssl_certificate /etc/nginx/ssl/tls.crt;
        ssl_certificate_key /etc/nginx/ssl/tls.key;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;
        ssl_protocols TLSv1.2;
        ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
        ssl_prefer_server_ciphers on;
        add_header Strict-Transport-Security max-age=15768000;
        ssl_stapling on;
        ssl_stapling_verify on;
      }
```

</details>

\
В `Service` зададим http и https порты:

<details>
<summary>Service manifest</summary>

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: srv-nginx
  namespace: ns-homework
spec:
  selector:
    app: myapp
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  - name: https
    port: 443
    targetPort: 443
    protocol: TCP
  type: NodePort
```

</details>

\
Создадим `Deployment` c nginx контейнером:

<details>
<summary>Deployment manifest</summary>

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-nginx
  namespace: ns-homework
  labels:
    app: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: nginx
          image: nginx:1.23.4
          resources:
            requests:
              memory: "64Mi"
              cpu: "125m"
            limits:
              memory: "128Mi"
              cpu: "250m"
          # Mounting the html page, default config with ssl, tls certificate
          volumeMounts:
            - name: tls-secret
              mountPath: /etc/nginx/ssl
            - name: html-page
              mountPath: /usr/share/nginx/html
            - name: default-config
              mountPath: /etc/nginx/conf.d
          ports:
            - containerPort: 80
            - containerPort: 443
      volumes:
        - name: tls-secret
          secret:
            secretName: secret-nginx
        - name: html-page
          configMap:
            name: configmap-html
        - name: default-config
          configMap:
            name: configmap-nginx
```

</details>

\
И создадим `Ingress` manifest с host = myapp.dev.local. Запись вида `127.0.0.1 myapp.dev.local` добавим в `/etc/hosts` нашей VM:

<details>
<summary>Ingress manifest</summary>

```yaml

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ing-nginx
  namespace: ns-homework
spec:
  tls:
  - hosts:
      - myapp.dev.local
    secretName: tls-secret
  rules:
  - host: myapp.dev.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: srv-nginx
            port:
              name: http
```

</details>

\
Проверяем доступ к нашей странице из VM:

```shell
ubuntu@ubuntu-mk8s:~$ curl http://myapp.dev.local
<html>
<head><title>308 Permanent Redirect</title></head>
<body>
<center><h1>308 Permanent Redirect</h1></center>
<hr><center>nginx</center>
</body>
</html>

ubuntu@ubuntu-mk8s:~$ curl https://myapp.dev.local -k
<!DOCTYPE html>
<html>
  <head>
    <title>Hello world!</title>
  </head>
  <body>
    <h1>This page hosted in my nginx pod.</h1>
  </body>
</html>
```
------

### Правила приёма работы

1. Домашняя работа оформляется в своём GitHub-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl`, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.

------