#!/bin/bash

#判断参数个数
if [ $# -lt 1 ]
then
  echo "not enough argument"
  exit;
fi

#遍历集群所有机器
for host in hadoop102 hadoop103 hadoop104
do
  echo ===================$host===================
  #遍历所有目录，发送
  for file in $@
  do
    #判断文件是否存在
	if [ -e $file ]
	then 
	  #获取父目录
	  pdir=$(cd -P $(dirname $file);pwd)
	  #获取当前文件名称
	  fname=$(basename $file)
	  ssh $host "mkdir -p $pdir"
	  rsync -av $pdir/$fname $host:$pdir
	else
	echo "file not exists"
	fi
  done
done
