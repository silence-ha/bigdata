#!/bin/bash

if [ $# -lt 1 ]
then
  echo "no args"
  exit;
fi

case $1 in
"start"){
	echo "----------------启动hadoop集群-------------------"
	echo "----------------启动hdfs-------------------"
	ssh hadoop102 "/opt/module/hadoop-3.1.3/sbin/start-dfs.sh"
	echo "----------------启动yarn-------------------"
	ssh hadoop103 "/opt/module/hadoop-3.1.3/sbin/start-yarn.sh"
	echo "----------------启动历史服务器-------------------"
	ssh hadoop102 "/opt/module/hadoop-3.1.3/bin/mapred --daemon start historyserver"
	
};;
"stop"){
    echo "----------------关闭hadoop集群-------------------"
	echo "----------------关闭历史服务器-------------------"
	ssh hadoop102 "/opt/module/hadoop-3.1.3/bin/mapred --daemon stop historyserver"
	echo "----------------关闭yarn-------------------"
	ssh hadoop103 "/opt/module/hadoop-3.1.3/sbin/stop-yarn.sh"
	echo "----------------关闭hdfs-------------------"
	ssh hadoop102 "/opt/module/hadoop-3.1.3/sbin/stop-dfs.sh"
};;
esac