# Домашнее задание к занятию «Микросервисы: принципы»

Вы работаете в крупной компании, которая строит систему на основе микросервисной архитектуры.
Вам как DevOps-специалисту необходимо выдвинуть предложение по организации инфраструктуры для разработки и эксплуатации.

## Задача 1: API Gateway

Предложите решение для обеспечения реализации API Gateway. Составьте сравнительную таблицу возможностей различных программных решений. На основе таблицы сделайте выбор решения.

Решение должно соответствовать следующим требованиям:

- маршрутизация запросов к нужному сервису на основе конфигурации,
- возможность проверки аутентификационной информации в запросах,
- обеспечение терминации HTTPS.

Обоснуйте свой выбор.

### Ответ

Для реализации API Gateway с вышеприведенными требованиями подойдут следующие готовые решения:
| API Name | Маршрутизация запросов / Requests routing | Аутентификация при запросах / Authentification layer | HTTPS Терминация / SSL/TLS termination |
| --- | --- | --- | --- |
| **Independent API (proprietary and open-source)** ||||
|Apigee| + | + | + |
|Axway| + | + | + |
|Gravitee.io API platform| + | + | + |
|HAProxy| + | + | + |
|Kong Gateway| + | + | + |
|||||
| **Cloud-based API** ||||
|AWS API Gateway| + | + | + |
|Azure API Gateway| + | + | + |
|Oracle API Gateway| + | + | + |
|SberCloud API Gateway| + | + | + |
|Yandex API Gateway| + | + | + |

На самом деле их гораздо больше.

В случаях, если наши сервисы используют облачные решения, то для меня видится логичным использование API облачных провайдеров - за счет их совместимости с другими технологиями и сервисами этих инфраструктур. Например AWS API для AWS cloud, или Yandex API Gateway для Yandex cloud. Такие решения обладают широкими возможностями, однако могут быть более затратны в использовании.

Следующие факторы выбора API gateway - активность и размер сообщества и динамика развития API, например за счет добавления в него модулей. Согласно Sourceforge, один из самых популярных - Kong Gateway. Имеет понятный API, множество клиентских библиотек и актуальную документацию. Использование API от сторонних производителей также обладают огромными возможностями кастомных настроек и модулей. Но на практике бывают случаи, когда выбранное решение может не подойти под требования бизнеса и выяснится это не сразу.

---

## Задача 2: Брокер сообщений

Составьте таблицу возможностей различных брокеров сообщений. На основе таблицы сделайте обоснованный выбор решения.

Решение должно соответствовать следующим требованиям:

- поддержка кластеризации для обеспечения надёжности,
- хранение сообщений на диске в процессе доставки,
- высокая скорость работы,
- поддержка различных форматов сообщений,
- разделение прав доступа к различным потокам сообщений,
- простота эксплуатации.

Обоснуйте свой выбор.

### Ответ

Проанализируем следующие брокеры:\
Apache ActiveMQ\
Apache Kafka\
Amazon Simple Queue Service\
IBM MQ\
RabbitMQ\
WSO2

| Message broker | Поддержка кластеризации / Clustering support | Хранение сообщений / Message store | Скорость работы / Broker speed | Форматы сообщений / Various message protocols | Разграничение права доступа / Message access restrictions | Простота эксплуатации / Ease of use |
| --- | --- | --- | --- | --- | --- | --- |
|Apache ActiveMQ| + | + | Быстрая |AMQP, STOMP, XMPP, MQTT| + | Да |
|Apache Kafka| + | + | Очень быстрая |Binary protocol over TCP| + | Да |
|Amazon SQS| + | + | Быстрая |HTTP(S) API| + | Нет |
|IBM MQ| + | + | Очень быстрая |AMQP, MQTT, STOMP| + | Нет |
|RabbitMQ| + | + | Быстрая |AMQP, MQTT, STOMP| + | Да |
|WSO2| + | + | Быстрая |AMQP, MQTT| + | Да |

Все перечисленные брокеры поддерживают кластеризацию и балансировку нагрузки. Как и в случае с API gateway, в облачных сервисах вашей инфраструктуры удобнее и практичнее использовать брокер сообщений того же провайдера. Скорость работы брокера зависит как от используемых брокером протоколов, так и от других требований: количество сообщений, которые должны быть обработаны в секунду; сообщения в реальном времени и сообщения с задержкойж количество серверов, доступных для вашего кластера, нужна ли вам потоковая передача и т.д.

Из приведенных примеров точно стоит рассмотреть Apache ActiveMQ, RabbitMQ и Apache Kafka. Первые два являются популярными классическими брокерами сообщений, обеспечивающие надежные гарантии доставки. Последний более многофункционален и подходит для приложений, требующих большей масштабируемости, производительности, порядка сообщений и более длительных периодов хранения.

---

## Задача 3: API Gateway * (необязательная)

### Есть три сервиса:

**minio**
- хранит загруженные файлы в бакете images,
- S3 протокол,

**uploader**
- принимает файл, если картинка сжимает и загружает его в minio,
- POST /v1/upload,

**security**
- регистрация пользователя POST /v1/user,
- получение информации о пользователе GET /v1/user,
- логин пользователя POST /v1/token,
- проверка токена GET /v1/token/validation.

### Необходимо воспользоваться любым балансировщиком и сделать API Gateway:

**POST /v1/register**
1. Анонимный доступ.
2. Запрос направляется в сервис security POST /v1/user.

**POST /v1/token**
1. Анонимный доступ.
2. Запрос направляется в сервис security POST /v1/token.

**GET /v1/user**
1. Проверка токена. Токен ожидается в заголовке Authorization. Токен проверяется через вызов сервиса security GET /v1/token/validation/.
2. Запрос направляется в сервис security GET /v1/user.

**POST /v1/upload**
1. Проверка токена. Токен ожидается в заголовке Authorization. Токен проверяется через вызов сервиса security GET /v1/token/validation/.
2. Запрос направляется в сервис uploader POST /v1/upload.

**GET /v1/user/{image}**
1. Проверка токена. Токен ожидается в заголовке Authorization. Токен проверяется через вызов сервиса security GET /v1/token/validation/.
2. Запрос направляется в сервис minio GET /images/{image}.

### Ожидаемый результат

Результатом выполнения задачи должен быть docker compose файл, запустив который можно локально выполнить следующие команды с успешным результатом.
Предполагается, что для реализации API Gateway будет написан конфиг для NGinx или другого балансировщика нагрузки, который будет запущен как сервис через docker-compose и будет обеспечивать балансировку и проверку аутентификации входящих запросов.
Авторизация
curl -X POST -H 'Content-Type: application/json' -d '{"login":"bob", "password":"qwe123"}' http://localhost/token

**Загрузка файла**

curl -X POST -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I' -H 'Content-Type: octet/stream' --data-binary @yourfilename.jpg http://localhost/upload

**Получение файла**
curl -X GET http://localhost/images/4e6df220-295e-4231-82bc-45e4b1484430.jpg

---

#### [Дополнительные материалы: как запускать, как тестировать, как проверить](https://github.com/netology-code/devkub-homeworks/tree/main/11-microservices-02-principles)

---

### Как оформить ДЗ?

Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.

--- 
