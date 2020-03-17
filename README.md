# kafka-docker

1. 构建镜像
docker build -t weiqichx/kafka_2.11:2.3.1 .

2. 运行容器
需要先启动zookeeper容器; 此处使用link的方式链接到zk集群. CMD 中没有使用 -daemon, 所以可以通过 docker logs 查看执行日志.
docker run --name kafka-broker --link zookeeper_zoo1_1:zoo1 --link zookeeper_zoo2_1:zoo2 --link zookeeper_zoo3_1:zoo3 --network zookeeper_default --restart always -p 9092:9092 -e "ZOO_CONNECT=zoo1:2181,zoo2:2181,zoo3:2181" -d weiqichx/kafka_2.11:2.3.1

注: Dockerfile的回车符号需要是(UNIX LF)类型, 否则无法执行CMD.