# example
# wget https://apache.uib.no/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz

# links
# https://github.com/earthquakesan/hdfs-spark-hive-dev-setup/blob/master/Makefile
# https://cwiki.apache.org/confluence/display/Hive/GettingStarted#GettingStarted-InstallationandConfiguration
#

root_dir 			= $$PWD
hive_version 		= 3.1.2
hadoop_version 		= 3.2.1
hive_home 			= $(PWD)/apache-hive-$(hive_version)-bin
hadoop_home 		= $(PWD)/hadoop-$(hadoop_version)

.PHONY: all download-hive download-hadoop configure-hive
all:

test:
	@echo $(hive_version)

download-hive:
	wget https://apache.uib.no/hive/hive-${hive_version}/apache-hive-${hive_version}-bin.tar.gz
	tar -xzvf apache-hive-${hive_version}-bin.tar.gz
	rm apache-hive-${hive_version}-bin.tar.gz
download-hadoop:
	wget https://apache.uib.no/hadoop/common/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz
	tar -xzvf hadoop-${hadoop_version}.tar.gz
	rm hadoop-${hadoop_version}.tar.gz

configure-hive:
	#Create hdfs folders
	${hadoop_home}/bin/hadoop fs -mkdir -p /tmp
	${hadoop_home}/bin/hadoop fs -mkdir -p /user/hive/warehouse
	${hadoop_home}/bin/hadoop fs -chmod g+w /tmp
	${hadoop_home}/bin/hadoop fs -chmod g+w /user/hive/warehouse