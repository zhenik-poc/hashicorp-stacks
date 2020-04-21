FROM openjdk:8-alpine AS hadoop-base
ENV HADOOP_VERSION 3.2.1

COPY  /*.crt /usr/local/share/ca-certificates/

RUN apk add --update --no-cache ca-certificates procps curl tar bash perl openssh wget \
    && update-ca-certificates 2>/dev/null || true \
    && rm -rf /var/cache/apk/*

ENV HADOOP_URL https://archive.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
RUN curl -s -L $HADOOP_URL | tar xz -C /opt/

RUN ln -s /opt/hadoop-$HADOOP_VERSION/etc/hadoop /etc/hadoop
RUN mkdir /opt/hadoop-$HADOOP_VERSION/logs

ENV HADOOP_HOME=/opt/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=/etc/hadoop
ENV USER=root
#ENV HDFS_DATANODE_USER=root
#ENV HDFS_DATANODE_SECURE_USER=root
ENV PATH $HADOOP_HOME/bin/:$PATH
# For secure daemons, this means both the secure and insecure env vars need to be
# defined.  e.g., HDFS_DATANODE_USER=root HDFS_DATANODE_SECURE_USER=hdfs

# config
RUN sed -i "s#.*export JAVA_HOME.*#export JAVA_HOME=${JAVA_HOME}#g" ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
RUN sed -i '/<\/configuration>/i <property><name>fs.defaultFS</name><value>hdfs://0.0.0.0:9000</value></property>' ${HADOOP_HOME}/etc/hadoop/core-site.xml
RUN sed -i '/<\/configuration>/i <property><name>dfs.replication</name><value>1</value></property>' ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
RUN ${HADOOP_HOME}/bin/hdfs namenode -format

CMD ${HADOOP_HOME}/sbin/start-dfs.sh