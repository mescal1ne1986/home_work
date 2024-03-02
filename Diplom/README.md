#  Дипломная работа по профессии «Системный администратор»
#  Трегубов Николай SYS-22


   
Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)
* [Выполнение работы](#Выполнение-работы)
* [Решение](#Решение)
<!-- * [Критерии сдачи](#Критерии-сдачи)
* [Как правильно задавать вопросы дипломному руководителю](#Как-правильно-задавать-вопросы-дипломному-руководителю) 
 -->
---------


## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**
 <details>
    
## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible.  

Не используйте для ansible inventory ip-адреса! Вместо этого используйте fqdn имена виртуальных машин в зоне ".ru-central1.internal". Пример: example.ru-central1.internal  

Важно: используйте по-возможности **минимальные конфигурации ВМ**:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая. 

**Так как прерываемая ВМ проработает не больше 24ч, перед сдачей работы на проверку дипломному руководителю сделайте ваши ВМ постоянно работающими.**

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Zabbix. На каждую ВМ установите Zabbix Agent, настройте агенты на отправление метрик в Zabbix. 

Настройте дешборды с отображением метрик, минимальный набор — по принципу USE (Utilization, Saturation, Errors) для CPU, RAM, диски, сеть, http запросов к веб-серверам. Добавьте необходимые tresholds на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Elasticsearch поместите в приватные подсети. Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh.  Эта вм будет реализовывать концепцию  [bastion host]( https://cloud.yandex.ru/docs/tutorials/routing/bastion) . Синоним "bastion host" - "Jump host". Подключение  ansible к серверам web и Elasticsearch через данный bastion host можно сделать с помощью  [ProxyCommand](https://docs.ansible.com/ansible/latest/network/user_guide/network_debug_troubleshooting.html#network-delegate-to-vs-proxycommand) . Допускается установка и запуск ansible непосредственно на bastion host.(Этот вариант легче в настройке)

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Zabbix можно реализовать разделение компонент - frontend, server, database. Frontend отдельной ВМ поместите в публичную подсеть, назначте публичный IP. Server поместите в приватную подсеть, настройте security group на разрешение трафика между frontend и server. Для Database используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Zabbix, через filebeat. Можно использовать logstash тоже.
4. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

</details>

## Выполнение работы

На этом этапе вы непосредственно выполняете работу. При этом вы можете консультироваться с руководителем по поводу вопросов, требующих уточнения.

⚠️ В случае недоступности ресурсов Elastic для скачивания рекомендуется разворачивать сервисы с помощью docker контейнеров, основанных на официальных образах.

**Важно**: Ещё можно задавать вопросы по поводу того, как реализовать ту или иную функциональность. И руководитель определяет, правильно вы её реализовали или нет. Любые вопросы, которые не освещены в этом документе, стоит уточнять у руководителя. Если его требования и указания расходятся с указанными в этом документе, то приоритетны требования и указания руководителя.


## Решение
 <details>
    
## Инфраструктура

1. По инструкции с [Yandex Cloud](https://cloud.yandex.com/) установил терраформ на локальную ВМ, создал новый сервисный аккаунт и настроил доступ к    облаку с локальной машины:
  <details>
     
![image](image/init.png)
</details>
     
2. Написал конфиг для инфраструктуры с помощью [terraform](https://github.com/Dk054/sys-diplom/tree/diplom-zabbix/Terraform) запустил его
<details>
   
![image](image/terraform_apply.png)
</details>
3. После развертывания инфраструктуры создаю вручную bastionhost и добавляю его в security groups, для установки  приложений с помощью Ansible 
4. Ставлю Ansible на bastionhost и проверяю:
<details>
   
[![Проверка](https://github.com/Dk054/sys-diplom/blob/38c73d0e665d476e4d08b32332a80bd164626910/image/ansible%20-i%20hosts%20all%20-m%20ping.png)
</details>

### Сайт

Создал две ВМ в разных зонах, ставлю на них сервера nginx [playbook-nginx.yml](https://github.com/Dk054/sys-diplom/tree/diplom-zabbix/Terraform), так же немного изменил конфиг html, в плейбуке описаны все действия, а именно установка, * установка начальной страницы сайта по шаблону html. 
Запускаю плейбук, проверяю что сайт доступен, заодно проверяю работу балансировщика
<details>
   
![установка](https://github.com/Dk054/sys-diplom/blob/diplom-zabbix/image/nginx%20установка.png)
![Сайт](https://github.com/Dk054/sys-diplom/blob/diplom-zabbix/image/сайт.png)
![Баланировщик](https://github.com/Dk054/sys-diplom/blob/diplom-zabbix/image/адрес%20балансировщика.png)
![Логи_балансировщика](https://github.com/Dk054/sys-diplom/blob/diplom-zabbix/image/логи%20балансировщика.png)

</details>

### Мониторинг
Использовал ansible galaxy для заббикс [сервера](https://github.com/Dk054/sys-diplom/tree/diplom-zabbix/Ansible/roles/zabbix-server) и [агента](https://github.com/Dk054/sys-diplom/tree/diplom-zabbix/Ansible/roles/zabbix-agent), для установки агента на ВМ использовал fqdn, для того что бы настроить дашборды, необходимо добавить хосты и прикрутить к ним шаблоны (использовал стандартные линукс+агент)

Установка:
<details>

![Vault](https://github.com/Dk054/sys-diplom/blob/a39299391225329496690072267f5bf2f0989b16/image/ansible-playbook%20-i%20hosts%20zabbix-server.yml%20--ask-vault-pass.png)
</details>
Дашборд:
<details>
   
![image](https://github.com/Dk054/sys-diplom/assets/139000762/b372c5b3-32b0-4628-97ed-47d7ddb0cc63)
![image](https://github.com/Dk054/sys-diplom/assets/139000762/74aef37d-79f8-4a45-950e-7232fe0e142c)


</details> 

### Логи
Сначала установил [Elasticsearch](https://github.com/Dk054/sys-diplom/blob/diplom-zabbix/Ansible/playbook-elastic.yml),потом [filebeat](https://github.com/Dk054/sys-diplom/blob/diplom-zabbix/Ansible/playbook-filebeat.yml) на ВМ, далее [Kibana](https://github.com/Dk054/sys-diplom/blob/diplom-zabbix/Ansible/playbook-kibana.yml), [конфиги](https://github.com/Dk054/sys-diplom/tree/diplom-zabbix/Ansible/configs) для них.

скриншоты:
<details>

Установка:
![image](https://github.com/Dk054/sys-diplom/assets/139000762/9257ea21-7e78-4446-8e05-d301476c8d57)
![image](https://github.com/Dk054/sys-diplom/assets/139000762/c6b15aa6-ec2f-495d-992e-e7cfd9cd380a)
![image](https://github.com/Dk054/sys-diplom/assets/139000762/b4a5b9c0-7082-4729-a1a3-811415091f40)
Проверки:
![image](https://github.com/Dk054/sys-diplom/assets/139000762/9596e6f8-0389-468f-928c-c0ac93129260)
![image](https://github.com/Dk054/sys-diplom/assets/139000762/5863c95a-15e1-4111-a9a7-a5f05e4c354d)
![image](https://github.com/Dk054/sys-diplom/assets/139000762/fa0e6a59-ca48-49b6-9a5f-5a521d574aec)


</details> 

### Сеть

<details>
   
Группы безопасности: 
![image](https://github.com/Dk054/sys-diplom/assets/139000762/3bb178bd-00c7-42fe-9752-0f3d95e77d35)
Шлюз:
![image](https://github.com/Dk054/sys-diplom/assets/139000762/b3a8a6df-75d7-4315-bc04-41ec6dd889f9)
Балансировщик
![image](https://github.com/Dk054/sys-diplom/assets/139000762/2912ddae-76b8-4f4c-8d96-a1fdbcbf00a7)
![image](https://github.com/Dk054/sys-diplom/assets/139000762/e00f31f3-d4a2-494a-8599-b4408528221e)
![image](https://github.com/Dk054/sys-diplom/assets/139000762/627c9005-48f2-43c6-ae97-f250cc6f4d30)

</details> 

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.
<details>

Резервное копирование было настроено с помощью terraform, [main.tf](https://github.com/Dk054/sys-diplom/blob/355cbd3a034e27a39538f8196173fea60751a720/Terraform/main.tf#L502)

![image](https://github.com/Dk054/sys-diplom/assets/139000762/a4ec32c9-a1cb-493c-911a-cc4b911cdcd4)

</details> 


## На этом всё, спасибо за просмотр :D
</details> 

<!-- 
## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Zabbix).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 

## Как правильно задавать вопросы дипломному руководителю
Что поможет решить большинство частых проблем:
1. Попробовать найти ответ сначала самостоятельно в интернете или в материалах курса и только после этого спрашивать у дипломного руководителя. Навык поиска ответов пригодится вам в профессиональной деятельности.
2. Если вопросов больше одного, присылайте их в виде нумерованного списка. Так дипломному руководителю будет проще отвечать на каждый из них.
3. При необходимости прикрепите к вопросу скриншоты и стрелочкой покажите, где не получается. Программу для этого можно скачать [здесь](https://app.prntscr.com/ru/).

Что может стать источником проблем:
1. Вопросы вида «Ничего не работает. Не запускается. Всё сломалось». Дипломный руководитель не сможет ответить на такой вопрос без дополнительных уточнений. Цените своё время и время других.
2. Откладывание выполнения дипломной работы на последний момент.
3. Ожидание моментального ответа на свой вопрос. Дипломные руководители — работающие инженеры, которые занимаются, кроме преподавания, своими проектами. Их время ограничено, поэтому постарайтесь задавать правильные вопросы, чтобы получать быстрые ответы :)
