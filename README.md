# kafka-docker

一. docker 构建 ZOOKEEPER 镜像
1. docker pull zookeeper:3.5.7
使用官方镜像

2. docker run --name zookeeper --restart always -p 2181:2181 -d zookeeper:3.5.7
运行容器, 建议使用 docker-compose 方式启动集群.


二. docker-compose 启动 ZOOKEEPER 集群.
1. docker-compose
PROJECT 项目: 一组关联的应用, 组成完整业务.
SERVICE 服务: 一个应用的容器, 可以多个实例.
参数: -p --project-name NAME, 指定一个 项目名称, 默认 目录名.
      -f --file FILE, 指定一个 compose file , 默认 docker-compose.yml

2. docker-compose -p zoo build 
如果通过 docker file 创建时需要先构建.

3. docker-compose -p zoo -f .\dockerfile\zoo-docker\docker-compose.yml create
创建项目中的容器, 每个服务是一个容器, 项目名_服务名_(扩展_ID) 组成容器名.

4. docker network create zoo_default 手动创建网络

5. docker-compose -p zoo -f .\dockerfile\zoo-docker\docker-compose.yml start
启动项目中的容器

6. docker-compose -p zoo -f .\dockerfile\zoo-docker\docker-compose.yml ps
查看项目中容器的状态
      Name                    Command               State                          Ports
----------------------------------------------------------------------------------------------------------------
zoo_zoo1_1   /docker-entrypoint.sh zkSe ...   Up      0.0.0.0:2181->2181/tcp, 2888/tcp, 3888/tcp, 8080/tcp
zoo_zoo2_1   /docker-entrypoint.sh zkSe ...   Up      0.0.0.0:2182->2181/tcp, 2888/tcp, 3888/tcp, 8080/tcp
zoo_zoo3_1   /docker-entrypoint.sh zkSe ...   Up      0.0.0.0:2183->2181/tcp, 2888/tcp, 3888/tcp, 8080/tcp

7. docker-compose -p zoo -f .\dockerfile\zoo-docker\docker-compose.yml stop
停止项目中的容器

8. docker-compose -p zoo -f .\dockerfile\zoo-docker\docker-compose.yml rm
移除停止服务的容器, 默认匿名的卷不被移除. 使用参数 -v 可以移除匿名卷. docker volume ls 查看所有卷.

9. docker-compose -p zoo -f .\dockerfile\zoo-docker\docker-compose.yml up
代替build, create, start等步骤.
自动完成包括构建镜像, 创建服务, 启动服务并关联服务相关容器的一系列操作
若未手动创建 network 则自动创建 network $PROJECT-NAME_default

10. docker-compose -p zoo -f .\dockerfile\zoo-docker\docker-compose.yml down
停止并移除服务, 网络, 镜像和卷. 会删除创建的 network ($PROJECT-NAME_default)


三. docker 构建 KAFKA 镜像
1. docker build -t weiqichx/kafka_2.11:2.3.1 .
通过 docker file 构建, Dockerfile的回车符号需要是(UNIX LF)类型, 否则无法执行CMD.

2. docker pull weiqichx/kafka_2.11:2.3.1
若不想构建可以通过 repo pull 镜像

3. docker run --name kafka-broker --link zoo_zoo1_1:zoo1 --link zoo_zoo2_1:zoo2 --link zoo_zoo3_1:zoo3 --network zoo_default --restart always -p 9092:9092 -e "ZOO_CONNECT=zoo1:2181,zoo2:2181,zoo3:2181" -d weiqichx/kafka_2.11:2.3.1
运行容器, 需要先启动zookeeper容器; 此处使用link的方式链接到zk集群. CMD 中没有使用 -daemon, 所以可以通过 docker logs 查看执行日志.


四. docker-compose 启动 KAFKA 集群.
1. docker-compose -p zoo -f .\dockerfile\kafka-docker\docker-compose.yml create
创建项目中的容器

2. docker-compose -p zoo -f .\dockerfile\kafka-docker\docker-compose.yml start
启动项目中的容器

3. docker-compose -p zoo -f .\dockerfile\kafka-docker\docker-compose.yml ps
查看项目中容器的状态
