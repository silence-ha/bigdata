Hive架构原理
  1．用户接口：Client 
     CLI（hive shell）、JDBC/ODBC(java访问hive)、WEBUI（浏览器访问hive）
  2．元数据：Metastore
     元数据包括：表名、表所属的数据库（默认是default）、表的拥有者、列/分区字段、表的类型（是否是外部表）、表的数据所在目录等；
  默认存储在自带的derby数据库中，推荐使用MySQL存储Metastore
  3．Hadoop
     使用HDFS进行存储，使用MapReduce进行计算。
  4．驱动器：Driver
   （1）解析器（SQL Parser）：将SQL字符串转换成抽象语法树AST，这一步一般都用第三方工具库完成，比如antlr；对AST进行语法分析，比如表是否存在、字段是否存在、SQL语义是否有误。
   （2）编译器（Physical Plan）：将AST编译生成逻辑执行计划。
   （3）优化器（Query Optimizer）：对逻辑执行计划进行优化。
   （4）执行器（Execution）：把逻辑执行计划转换成可以运行的物理计划。对于Hive来说，就是MR/Spark。
Hive安装
  1．Hive安装及配置
    1）把 apache-hive-3.1.2-bin.tar.gz 上传到 linux 的/opt/software 目录下
    2）解压 apache-hive-3.1.2-bin.tar.gz 到/opt/module/目录下面
        tar -zxvf /opt/software/apache-hive-3.1.2-bin.tar.gz -C /opt/module/
    3）修改 apache-hive-3.1.2-bin.tar.gz 的名称为 hive
        mv /opt/module/apache-hive-3.1.2-bin/ /opt/module/hive
    4）修改/etc/profile.d/my_env.sh，添加环境变量
	    sudo vim /etc/profile.d/my_env.sh
        #HIVE_HOME
        export HIVE_HOME=/opt/module/hive
        export PATH=$PATH:$HIVE_HOME/bin
    5）解决日志 Jar 包冲突
      mv $HIVE_HOME/lib/log4j-slf4j-impl-2.10.0.jar $HIVE_HOME/lib/log4j-slf4j-impl-2.10.0.bak
    6）初始化元数据库
	   bin/schematool -dbType derby -initSchema
  2.MySQL 安装
    1）检查当前系统是否安装过 MySQL  
      rpm -qa|grep mariadb 
	  //如果存在通过如下命令卸载
      sudo rpm -e --nodeps mariadb-libs
	2）将 MySQL 安装包拷贝到/opt/software 目录下
	3）解压 MySQL 安装包
      tar -xf mysql-5.7.28-1.el7.x86_64.rpm-bundle.tar
	4）在安装目录下执行 rpm 安装
	  sudo rpm -ivh mysql-community-common-5.7.28-1.el7.x86_64.rpm
      sudo rpm -ivh mysql-community-libs-5.7.28-1.el7.x86_64.rpm
      sudo rpm -ivh mysql-community-libs-compat-5.7.28-1.el7.x86_64.rpm
      sudo rpm -ivh mysql-community-client-5.7.28-1.el7.x86_64.rpm
      sudo rpm -ivh mysql-community-server-5.7.28-1.el7.x86_64.rpm
      注意:按照顺序依次执行
	  如果 Linux 是最小化安装的，在安装 mysql-community-server-5.7.28-1.el7.x86_64.rpm 时可能会出现如下错误
	  警告：mysql-community-server-5.7.28-1.el7.x86_64.rpm: 头 V3 DSA/SHA1 Signature, 密钥 ID 5072e1f5: NOKEY
       错误：依赖检测失败：
        libaio.so.1()(64bit) 被 mysql-community-server-5.7.28-1.el7.x86_64 
       需要
        libaio.so.1(LIBAIO_0.1)(64bit) 被 mysql-community-server-5.7.28-
       1.el7.x86_64 需要
        libaio.so.1(LIBAIO_0.4)(64bit) 被 mysql-community-server-5.7.28-
       1.el7.x86_64 需要
	   通过 yum 安装缺少的依赖,然后重新安装 mysql-community-server-5.7.28-1.el7.x86_64 即可
	   yum install -y libaio
	5）删除/etc/my.cnf 文件中 datadir 指向的目录下的所有内容,如果有内容的情况下:
	   查看 datadir 的值：
       [mysqld]
       datadir=/var/lib/mysql
       删除/var/lib/mysql 目录下的所有内容:
       [silence @hadoop102 mysql]# cd /var/lib/mysql
       [silence @hadoop102 mysql]# sudo rm -rf ./* //注意执行命令的位置
	6）初始化数据库
       sudo mysqld --initialize --user=mysql
	7）查看临时生成的 root 用户的密码
        sudo cat /var/log/mysqld.log
    8）启动 MySQL 服务
	     sudo systemctl start mysqld
	9）登录 MySQL 数据库
       mysql -uroot -p
       Enter password: 输入临时生成的密码
        登录成功.
    10）必须先修改 root 用户的密码,否则执行其他的操作会报错
        mysql> set password = password("新密码");
    11）修改 mysql 库下的 user 表中的 root 用户允许任意 ip 连接
        mysql> update mysql.user set host='%' where user='root';
        mysql> flush privileges;
  3.Hive 元数据配置到 MySQL
    将 MySQL 的 JDBC 驱动拷贝到 Hive 的 lib 目录下
	  cp /opt/software/mysql-connector-java-5.1.37.jar $HIVE_HOME/lib
	配置 Metastore 到 MySQL
	     vim $HIVE_HOME/conf/hive-site.xml
         <?xml version="1.0"?>
         <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
         <configuration>
          <!-- jdbc 连接的 URL -->
          <property>
          <name>javax.jdo.option.ConnectionURL</name>
          <value>jdbc:mysql://hadoop102:3306/metastore?useSSL=false</value>
         </property>
          <!-- jdbc 连接的 Driver-->
          <property>
          <name>javax.jdo.option.ConnectionDriverName</name>
          <value>com.mysql.jdbc.Driver</value>
         </property>
         <!-- jdbc 连接的 username-->
          <property>
          <name>javax.jdo.option.ConnectionUserName</name>
          <value>root</value>
          </property>
          <!-- jdbc 连接的 password -->
          <property>
          <name>javax.jdo.option.ConnectionPassword</name>
          <value>000000</value>
         </property>
          <!-- Hive 元数据存储版本的验证 -->
          <property>
          <name>hive.metastore.schema.verification</name>
          <value>false</value>
         </property>
          <!--元数据存储授权-->
          <property>
          <name>hive.metastore.event.db.notification.api.auth</name>
          <value>false</value>
          </property>
          <!-- Hive 默认在 HDFS 的工作目录 -->
          <property>
          <name>hive.metastore.warehouse.dir</name>
          <value>/user/hive/warehouse</value>
          </property>
         </configuration>
	    2）登陆 MySQL
	    3）新建 Hive 元数据库
	        mysql> create database metastore;
            mysql> quit;
        4） 初始化 Hive 元数据库
	    schematool -initSchema -dbType mysql -verbose
    使用元数据服务的方式访问 Hive
	   1）在 hive-site.xml 文件中添加如下配置信息
       <!-- 指定存储元数据要连接的地址 -->
       <property>
       <name>hive.metastore.uris</name>
       <value>thrift://hadoop102:9083</value>
       </property>
      2）启动 metastore
      [silence@hadoop202 hive]$ hive --service metastore
     
      注意: 启动后窗口不能再操作，需打开一个新的 shell 窗口做别的操作
    使用 JDBC 方式访问 Hive
	    1）在 hive-site.xml 文件中添加如下配置信息
          <!-- 指定 hiveserver2 连接的 host -->
          <property>
          <name>hive.server2.thrift.bind.host</name> 
          <value>hadoop102</value>
          </property>
          <!-- 指定 hiveserver2 连接的端口号 -->
          <property>
          <name>hive.server2.thrift.port</name>
          <value>10000</value>
          </property>
		2）启动 hiveserver2
           bin/hive --service hiveserver2
        3）启动 beeline 客户端（需要多等待一会）
		   bin/beeline -u jdbc:hive2://hadoop102:10000 -n silence
		4）编写 hive 服务启动脚本
		   nohup hive --service metastore 2>&1 &
           nohup hive --service hiveserver2 2>&1 &
           #!/bin/bash
           HIVE_LOG_DIR=$HIVE_HOME/logs
           if [ ! -d $HIVE_LOG_DIR ]
           then
           mkdir -p $HIVE_LOG_DIR
           fi
           #检查进程是否运行正常，参数 1 为进程名，参数 2 为进程端口
           function check_process() 
           {
            pid=$(ps -ef 2>/dev/null | grep -v grep | grep -i $1 | awk '{print $2}')
            ppid=$(netstat -nltp 2>/dev/null | grep $2 | awk '{print $7}' | cut -d '/' -f 1)
            echo $pid
            [[ "$pid" =~ "$ppid" ]] && [ "$ppid" ] && return 0 || return 1
           }
           function hive_start()
           {
            metapid=$(check_process HiveMetastore 9083)
            cmd="nohup hive --service metastore >$HIVE_LOG_DIR/metastore.log 2>&1 &"
            [ -z "$metapid" ] && eval $cmd || echo "Metastroe 服务已启动"
            server2pid=$(check_process HiveServer2 10000)
            cmd="nohup hiveserver2 >$HIVE_LOG_DIR/hiveServer2.log 2>&1 &"
            [ -z "$server2pid" ] && eval $cmd || echo "HiveServer2 服务已启动"
           }
           function hive_stop()
           {
            metapid=$(check_process HiveMetastore 9083)
            [ "$metapid" ] && kill $metapid || echo "Metastore 服务未启动"
            server2pid=$(check_process HiveServer2 10000)
            [ "$server2pid" ] && kill $server2pid || echo "HiveServer2 服务未启动"
           }
           case $1 in
           "start")
            hive_start
            ;;
           "stop")
            hive_stop
            ;;
           "restart")
            hive_stop
            sleep 2
            hive_start
            ;;
           "status")
            check_process HiveMetastore 9083 >/dev/null && echo "Metastore 服务运行正常" || echo "Metastore 服务运行异常"
            check_process HiveServer2 10000 >/dev/null && echo "HiveServer2 服务运行正常" || echo "HiveServer2 服务运行异常"
            ;;
            *)
            echo Invalid Args!
            echo 'Usage: '$(basename $0)' start|stop|restart|status'
            ;;
           esac
		3）添加执行权限
		4）启动 Hive 后台服务
    Hive 常用交互命令
	    1）“-e”不进入 hive 的交互窗口执行 sql 语句
           bin/hive -e "select id from student;"
        2）“-f”执行脚本中 sql 语句
		   bin/hive -f /opt/module/hive/datas/hivef.sql > /opt/module/datas/hive_result.txt
        3)在 hive cli 命令窗口中如何查看 hdfs 文件系统
          hive(default)>dfs -ls /;
		4)查看在 hive 中输入的所有历史命令
          （1）进入到当前用户的根目录 /root 或/home/atguigu
          （2）查看. hivehistory 文件
               cat .hivehistory
    Hive 常见属性配置
	    1)修改 hive 的 log 存放日志到/opt/module/hive/logs
		    在 hive-log4j2.properties 文件中修改 log 存放位置
            hive.log.dir=/opt/module/hive/logs
	    2)打印 当前库 和 表头
		   在 hive-site.xml 中加入如下两个配置:
           <property>
           <name>hive.cli.print.header</name>
           <value>true</value>
           </property>
           <property>
           <name>hive.cli.print.current.db</name>
           <value>true</value>
           </property>
		3)
		row format delimited fields terminated by ',' -- 列分隔符
        collection items terminated by '_' --MAP STRUCT 和 ARRAY 的分隔符(数据分割符号)
        map keys terminated by ':' -- MAP 中的 key 与 value 的分隔符
        lines terminated by '\n'; -- 行分隔符
		4）显示数据库信息
           hive> desc database db_hive;
           
        5）显示数据库详细信息，extended
           hive> desc database extended db_hive;
    创建表
	   CREATE [EXTERNAL] TABLE [IF NOT EXISTS] table_name
       [(col_name data_type [COMMENT col_comment], ...)]
       [COMMENT table_comment]
       [PARTITIONED BY (col_name data_type [COMMENT col_comment], ...)]
       [CLUSTERED BY (col_name, col_name, ...)
       [SORTED BY (col_name [ASC|DESC], ...)] INTO num_buckets BUCKETS]
       [ROW FORMAT row_format]
       [STORED AS file_format]
       [LOCATION hdfs_path]
       [TBLPROPERTIES (property_name=property_value, ...)]
       [AS select_statement]
	   管理表与外部表的互相转换
	   （1）查询表的类型
           hive (default)> desc formatted student2;
           Table Type: MANAGED_TABLE
           （2）修改内部表 student2 为外部表
           alter table student2 set tblproperties('EXTERNAL'='TRUE');
           （3）查询表的类型
           hive (default)> desc formatted student2;
           Table Type: EXTERNAL_TABLE
           （4）修改外部表 student2 为内部表
           alter table student2 set tblproperties('EXTERNAL'='FALSE');
           （5）查询表的类型
           hive (default)> desc formatted student2;
           Table Type: MANAGED_TABLE
          注意：('EXTERNAL'='TRUE')和('EXTERNAL'='FALSE')为固定写法，区分大小写！

    数据导入
	   向表中装载数据（Load）
         hive> load data [local] inpath '数据的 path' [overwrite] into table student [partition (partcol1=val1,…)];
       （1）load data:表示加载数据
       （2）local:表示从本地加载数据到 hive 表；否则从 HDFS 加载数据到 hive 表
       （3）inpath:表示加载数据的路径
       （4）overwrite:表示覆盖表中已有数据，否则表示追加
       （5）into table:表示加载到哪张表
       （6）student:表示具体的表
       （7）partition:表示上传到指定分区
      通过查询语句向表中插入数据（Insert）
         insert overwrite table student_par select id, name from student where month='201709';
         insert into：以追加数据的方式插入到表或分区，原有数据不会删除
         insert overwrite：会覆盖表中已存在的数据
         注意：insert 不支持插入部分字段
	  查询语句中创建表并加载数据（As Select）
	  创建表时通过 Location 指定加载数据路径
          create external table if not exists student5(
           id int, name string
          )
         row format delimited fields terminated by '\t'
         location '/student;
	  Import 数据到指定 Hive 表中
         注意：先用 export 导出后，再将数据导入。
         hive (default)> import table student2 from '/user/hive/warehouse/export/student';
    数据导出
	  Insert 导出
	    将查询的结果格式化导出到本地
        hive(default)>insert overwrite local directory '/opt/module/hive/data/export/student1'
        ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
        select * from student;
	  Hadoop 命令导出到本地
	    hive (default)> dfs -get /user/hive/warehouse/student/student.txt /opt/module/data/export/student3.txt;
      Hive Shell 命令导出
        bin/hive -e 'select * from default.student;' >/opt/module/hive/data/export/student4.txt;
	  Export 导出到 HDFS 上
	     export table default.student to '/user/hive/warehouse/export/student';
         export 和 import 主要用于两个 Hadoop 平台集群之间 Hive 表迁移。
      Sqoop 导出
	排序
        Order By：全局排序，只有一个 Reducer
		Sort By：对于大规模的数据集 order by 的效率非常低。在很多情况下，并不需要全局排序，此时可以使用 sort by。
        Sort by 为每个 reducer 产生一个排序文件。每个 Reducer 内部进行排序，对全局结果集来说不是排序。
        Distribute By： 在有些情况下，我们需要控制某个特定行应该到哪个 reducer，通常是为了进行后续的聚集操作。distribute by 子句可以做这件事。distribute by 类似 MR 中 partition（自定义分区），进行分区，结合 sort by 使用。
        对于 distribute by 进行测试，一定要分配多 reduce 进行处理，否则无法看到 distribute by 的效果。
		注意：
         ➢ distribute by 的分区规则是根据分区字段的 hash 码与 reduce 的个数进行模除后，余数相同的分到一个区。
         ➢ Hive 要求 DISTRIBUTE BY 语句要写在 SORT BY 语句之前。
		当 distribute by 和 sorts by 字段相同时，可以使用 cluster by 方式。
           cluster by 除了具有 distribute by 的功能外还兼具 sort by 的功能。但是排序只能是升序排序，不能指定排序规则为 ASC 或者 DESC。
    把数据直接上传到分区目录上，让分区表和数据产生关联的三种方式
	   （1）方式一：上传数据后修复
	       hive> msck repair table dept_partition2;
       （2）方式二：上传数据后添加分区
          hive (default)> alter table dept_partition2 add partition(day='201709',hour='14');
	   （3）方式三：创建文件夹后 load 数据到分区
	       load data local inpath '/opt/module/hive/datas/dept_20200401.log' into table dept_partition2 partition(day='20200401',hour='15');
    动态分区调整
	  1）开启动态分区参数设置
         （1）开启动态分区功能（默认 true，开启）
         hive.exec.dynamic.partition=true
         （2）设置为非严格模式（动态分区的模式，默认 strict，表示必须指定至少一个分区为静态分区，nonstrict 模式表示允许所有的分区字段都可以使用动态分区。）
         hive.exec.dynamic.partition.mode=nonstrict
         （3）在所有执行 MR 的节点上，最大一共可以创建多少个动态分区。默认 1000
         hive.exec.max.dynamic.partitions=1000
         （4）在每个执行 MR 的节点上，最大可以创建多少个动态分区。该参数需要根据实际
         的数据来设定。比如：源数据中包含了一年的数据，即 day 字段有 365 个值，那么该参数就
         需要设置成大于 365，如果使用默认值 100，则会报错。
         hive.exec.max.dynamic.partitions.pernode=100
         （5）整个 MR Job 中，最大可以创建多少个 HDFS 文件。默认 100000
         hive.exec.max.created.files=100000
         （6）当有空分区生成时，是否抛出异常。一般不需要设置。默认 false
         hive.error.on.empty.partition=false
		 
		 设置动态分区
	     set hive.exec.dynamic.partition.mode = nonstrict;
         hive (default)> insert into table dept_partition_dy partition(loc) select deptno, dname, loc from dept;
        查看目标分区表的分区情况
         hive (default)> show partitions dept_partition;
    分桶表
	   分区提供一个隔离数据和优化查询的便利方式。不过，并非所有的数据集都可形成合理的分区。对于一张表或者分区，Hive 可以进一步组织成桶，也就是更为细粒度的数据范围划分。
       分桶是将数据集分解成更容易管理的若干部分的另一个技术。
       分区针对的是数据的存储路径；分桶针对的是数据文件。
       分桶表操作需要注意的事项:
     （1）reduce 的个数设置为-1,让 Job 自行决定需要用多少个 reduce 或者将 reduce 的个
       数设置为大于等于分桶表的桶数
     （2）从 hdfs 中 load 数据到分桶表中，避免本地文件找不到问题 
     （3）不要使用本地模式
    行转列
	   CONCAT(string A/col, string B/col…)：返回输入字符串连接后的结果，支持任意个输入字符串;
       CONCAT_WS(separator, str1, str2,...)：它是一个特殊形式的 CONCAT()。第一个参数剩余参
        数间的分隔符。分隔符可以是与剩余参数一样的字符串。如果分隔符是 NULL，返回值也将
        为 NULL。这个函数会跳过分隔符参数后的任何 NULL 和空字符串。分隔符将被加到被连接 的字符串之间;
       注意: CONCAT_WS must be "string or array<string>
	   COLLECT_SET(col)：函数只接受基本数据类型，它的主要作用是将某字段的值进行去重汇总，产生 Array 类型字段。
	   
	列转行
	   EXPLODE(col)：将 hive 一列中复杂的 Array 或者 Map 结构拆分成多行。
       LATERAL VIEW
       用法：LATERAL VIEW udtf(expression) tableAlias AS columnAlias
       解释：用于和 split, explode 等 UDTF 一起使用，它能够将一列数据拆成多行数据，在此
       基础上可以对拆分后的数据进行聚合。
	   
	窗口函数
       OVER()：指定分析函数工作的数据窗口大小，这个数据窗口大小可能会随着行的变而变化。
       CURRENT ROW：当前行
       n PRECEDING：往前 n 行数据
       n FOLLOWING：往后 n 行数据
       UNBOUNDED：起点，
       UNBOUNDED PRECEDING 表示从前面的起点，
        UNBOUNDED FOLLOWING 表示到后面的终点
       LAG(col,n,default_val)：往前第 n 行数据
       LEAD(col,n, default_val)：往后第 n 行数据
       NTILE(n)：把有序窗口的行分发到指定数据的组中，各个组有编号，编号从 1 开始，对
       于每一行，NTILE 返回此行所属的组的编号。注意：n 必须为 int 类型。
	   
       select name,orderdate,cost,
       sum(cost) over() as sample1,--所有行相加
       sum(cost) over(partition by name) as sample2,--按 name 分组，组内数据相加
       sum(cost) over(partition by name order by orderdate) as sample3,--按 name分组，组内数据累加
       sum(cost) over(partition by name order by orderdate rows between 
       UNBOUNDED PRECEDING and current row ) as sample4 ,--和 sample3 一样,由起点到当前行的聚合
       sum(cost) over(partition by name order by orderdate rows between 1 
       PRECEDING and current row) as sample5, --当前行和前面一行做聚合
       sum(cost) over(partition by name order by orderdate rows between 1 
       PRECEDING AND 1 FOLLOWING ) as sample6,--当前行和前边一行及后面一行
       sum(cost) over(partition by name order by orderdate rows between current 
       row and UNBOUNDED FOLLOWING ) as sample7 --当前行及后面所有行
       from business;
	   rows 必须跟在 order by 子句之后，对排序的结果进行限制，使用固定的行数来限制分区中的数据行数量

       RANK() 排序相同时会重复，总数不会变
       DENSE_RANK() 排序相同时会重复，总数会减少
       ROW_NUMBER() 会根据顺序计算
    自定义 UDF 函数
	    导入依赖
          <dependencies>
          <dependency>
          <groupId>org.apache.hive</groupId>
          <artifactId>hive-exec</artifactId>
          <version>3.1.2</version>
          </dependency>
          </dependencies>
		  
		     /**
             * 自定义 UDF 函数，需要继承 GenericUDF 类
             * 需求: 计算指定字符串的长度
             */
             public class MyStringLength extends GenericUDF {
              /**
              *
              * @param arguments 输入参数类型的鉴别器对象
              * @return 返回值类型的鉴别器对象
              * @throws UDFArgumentException
              */
              @Override
              public ObjectInspector initialize(ObjectInspector[] arguments) throws UDFArgumentException { 
              // 判断输入参数的个数
              if(arguments.length !=1){
              throw new UDFArgumentLengthException("Input Args Length Error!!!");
              }
              // 判断输入参数的类型
              
             if(!arguments[0].getCategory().equals(ObjectInspector.Category.PRIMITIVE)){
              throw new UDFArgumentTypeException(0,"Input Args Type Error!!!");
              }
              //函数本身返回值为 int，需要返回 int 类型的鉴别器对象
              return PrimitiveObjectInspectorFactory.javaIntObjectInspector;
              }
              /**
              * 函数的逻辑处理
              * @param arguments 输入的参数
              * @return 返回值
              * @throws HiveException
              */
              @Override
              public Object evaluate(DeferredObject[] arguments) throws HiveException {
              if(arguments[0].get() == null){
              return 0;
              }
              return arguments[0].get().toString().length();
              }
              @Override
              public String getDisplayString(String[] children) {
              return "";
              }
             }
        打成 jar 包上传到服务器/opt/module/data/myudf.jar
		将 jar 包添加到 hive 的 classpath
             hive (default)> add jar /opt/module/data/myudf.jar;
        创建临时函数与开发好的 java class 关联
             hive (default)> create temporary function my_len as "com.silence.hive.MyStringLength";
		即可在 hql 中使用自定义的函数
            hive (default)> select ename,my_len(ename) ename_len from emp;
	    或 CREATE temporary FUNCTION default.add AS 'com.bigdata.Add' USING JAR 'hdfs://service/add.jar';
	自定义 UDTF 函数
        public class MyUDTF extends GenericUDTF {
         private ArrayList<String> outList = new ArrayList<>();
         @Override
         public StructObjectInspector initialize(StructObjectInspector argOIs) throws UDFArgumentException {
         //1.定义输出数据的列名和类型
         List<String> fieldNames = new ArrayList<>();
         List<ObjectInspector> fieldOIs = new ArrayList<>();
         //2.添加输出数据的列名和类型
         fieldNames.add("lineToWord");
         
        fieldOIs.add(PrimitiveObjectInspectorFactory.javaStringObjectInspector);
         return 
        ObjectInspectorFactory.getStandardStructObjectInspector(fieldNames, fieldOIs);
         }
         @Override
         public void process(Object[] args) throws HiveException {
         
         //1.获取原始数据
         String arg = args[0].toString();
         //2.获取数据传入的第二个参数，此处为分隔符
         String splitKey = args[1].toString();
         //3.将原始数据按照传入的分隔符进行切分
         String[] fields = arg.split(splitKey); 
         //4.遍历切分后的结果，并写出
         for (String field : fields) {
         //集合为复用的，首先清空集合
         outList.clear();
         //将每一个单词添加至集合
         outList.add(field);
         //将集合内容写出
         forward(outList);
         }
         }
         @Override
         public void close() throws HiveException {
         }
        }
    开启 Map 输出阶段压缩
	   （1）开启 hive 中间传输数据压缩功能
       hive (default)>set hive.exec.compress.intermediate=true;
       （2）开启 mapreduce 中 map 输出压缩功能
       hive (default)>set mapreduce.map.output.compress=true;
       （3）设置 mapreduce 中 map 输出数据的压缩方式
       hive (default)>set mapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.SnappyCodec;
       （4）执行查询语句
       hive (default)> select count(ename) name from emp;
	开启 Reduce 输出阶段压缩
        （1）开启 hive 最终输出数据压缩功能
        hive (default)>set hive.exec.compress.output=true;
        （2）开启 mapreduce 最终输出数据压缩
        hive (default)>set mapreduce.output.fileoutputformat.compress=true;
        （3）设置 mapreduce 最终数据输出压缩方式
        hive (default)> set mapreduce.output.fileoutputformat.compress.codec =org.apache.hadoop.io.compress.SnappyCodec;
        （4）设置 mapreduce 最终数据输出压缩为块压缩
        hive (default)> set mapreduce.output.fileoutputformat.compress.type=BLOCK;
        （5）测试一下输出结果是否是压缩文件
        hive (default)> insert overwrite local directory
        '/opt/module/data/distribute-result' select * from emp distribute by deptno sort by empno desc;
    文件存储格式
	   Hive 支持的存储数据的格式主要有：TEXTFILE 、SEQUENCEFILE、ORC、PARQUET
	   TEXTFILE 和 SEQUENCEFILE 的存储格式都是基于行存储的；
	   ORC 和 PARQUET 是基于列式存储的
 企业级调优
    查看详细执行计划
       hive (default)> explain extended select * from emp;
       hive (default)> explain extended select deptno, avg(sal) avg_sal from emp group by deptno;
	Fetch 抓取
	   （1）把 hive.fetch.task.conversion 设置成 none，然后执行查询语句，都会执行 mapreduce程序。
	        hive (default)> set hive.fetch.task.conversion=none;
       （2）把 hive.fetch.task.conversion 设置成 more，然后执行查询语句，如下查询方式都不会执行 mapreduce 程序。
            hive (default)> set hive.fetch.task.conversion=more;
            hive (default)> select * from emp;
            hive (default)> select ename from emp;
            hive (default)> select ename from emp limit 3;
	本地模式
        Hive 可以通过本地模式在单台机器上处理所有的任务。对于小数据集，执行时间可以明显被缩短。
        用户可以通过设置 hive.exec.mode.local.auto 的值为 true，来让 Hive 在适当的时候自动启动这个优化。
        set hive.exec.mode.local.auto=true; //开启本地 mr
        //设置 local mr 的最大输入数据量，当输入数据量小于这个值时采用 local mr 的方式，默认为 134217728，即 128M
        set hive.exec.mode.local.auto.inputbytes.max=50000000;
        //设置 local mr 的最大输入文件个数，当输入文件个数小于这个值时采用 local mr 的方式，默认为 4
        set hive.exec.mode.local.auto.input.files.max=10;
    表的优化
	    小表大表 Join（MapJOIN）
		实际测试发现：新版的 hive 已经对小表 JOIN 大表和大表 JOIN 小表进行了优化。小表放在左边和右边已经没有区别。
        （1）设置自动选择 Mapjoin
            set hive.auto.convert.join = true; 默认为 true
        （2）大表小表的阈值设置（默认 25M 以下认为是小表）：
           set hive.mapjoin.smalltable.filesize = 25000000;
	大表 Join 大表
        1）空 KEY 过滤
        2）空 key 转换
          insert overwrite table jointable select n.* from nullidtable n full join bigtable o on nvl(n.id,rand()) = o.id;
		3）SMB(Sort Merge Bucket join)
    Group By
	    1）开启 Map 端聚合参数设置
		  （1）是否在 Map 端进行聚合，默认为 True
          set hive.map.aggr = true
          （2）在 Map 端进行聚合操作的条目数目
          set hive.groupby.mapaggr.checkinterval = 100000
          （3）有数据倾斜的时候进行负载均衡（默认是 false）
          set hive.groupby.skewindata = true
		当选项设定为 true，生成的查询计划会有两个 MR Job。第一个 MR Job 中，Map 的输出结果会随机分布到 Reduce 中，每个 Reduce 做部分聚合操作，并输出结果，这样处理的结果
        是相同的 Group By Key 有可能被分发到不同的 Reduce 中，从而达到负载均衡的目的；第二个 MR Job 再根据预处理的数据结果按照 Group By Key 分布到 Reduce 中（这个过程可以保证
        相同的 Group By Key 被分布到同一个 Reduce 中），最后完成最终的聚合操作。
    Count(Distinct) 去重统计
        由于 COUNT DISTINCT 操作需要用一个Reduce Task 来完成，这一个 Reduce 需要处理的数据量太大，就会导致整个 Job 很难完成，
       一般 COUNT DISTINCT 使用先 GROUP BY 再 COUNT 的方式替换,但是需要注意 group by 造成的数据倾斜问题.
	   select count(id) from (select id from bigtable group by id) a;
	   虽然会多用一个 Job 来完成，但在数据量大的情况下，这个绝对是值得的。
	笛卡尔积
	   尽量避免笛卡尔积，join 的时候不加 on 条件，或者无效的 on 条件，Hive 只能使用 1 个reducer 来完成笛卡尔积。
	行列过滤
	    列处理：在 SELECT 中，只拿需要的列，如果有分区，尽量使用分区过滤，少用 SELECT *。
        行处理：在分区剪裁中，当使用外关联时，如果将副表的过滤条件写在 Where 后面，那么就会先全表关联，之后再过滤
    合理设置 Map 及 Reduce 数
    复杂文件增加 Map 数
	    当 input 的文件都很大，任务逻辑复杂，map 执行非常慢的时候，可以考虑增加 Map 数，来使得每个 map 处理的数据量减少，从而提高任务的执行效率。
       增加 map 的方法为：根据computeSliteSize(Math.max(minSize,Math.min(maxSize,blocksize)))=blocksize=128M 公式，
       调整 maxSize 最大值。让 maxSize 最大值低于 blocksize 就可以增加 map 的个数。
       设置最大切片值为 100 个字节
        hive (default)> set mapreduce.input.fileinputformat.split.maxsize=100;
    小文件进行合并
        1）在 map 执行前合并小文件，减少 map 数：CombineHiveInputFormat 具有对小文件进行合并的功能（系统默认的格式）。
		HiveInputFormat 没有对小文件合并功能。
        set hive.input.format= org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
		2）在 Map-Reduce 的任务结束时合并小文件的设置：
           在 map-only 任务结束时合并小文件，默认 true
           SET hive.merge.mapfiles = true;
           在 map-reduce 任务结束时合并小文件，默认 false
            SET hive.merge.mapredfiles = true;
          合并文件的大小，默认 256M
           SET hive.merge.size.per.task = 268435456;
          当输出文件的平均大小小于该值时，启动一个独立的 map-reduce 任务进行文件 merge
           SET hive.merge.smallfiles.avgsize = 16777216;
    合理设置 Reduce 数
	    （1）每个 Reduce 处理的数据量默认是 256MB
            hive.exec.reducers.bytes.per.reducer=256000000
        （2）每个任务最大的 reduce 数，默认为 1009
            hive.exec.reducers.max=1009
        （3）计算 reducer 数的公式
            N=min(参数 2，总输入数据量/参数 1)

         在 hadoop 的 mapred-default.xml 文件中修改
         设置每个 job 的 Reduce 个数
           set mapreduce.job.reduces = 15;
	并行执行
	    set hive.exec.parallel=true; //打开任务并行执行
        set hive.exec.parallel.thread.number=16; //同一个 sql 允许最大并行度，默认为8。
        当然，得是在系统资源比较空闲的时候才有优势，否则，没资源，并行也起不来。
    严格模式
	    1）分区表不使用分区过滤
        将 hive.strict.checks.no.partition.filter 设置为 true 时，对于分区表，除非 where 语句中含有分区字段过滤条件来限制范围，否则不允许执行
		2）使用 order by 没有 limit 过滤
		将 hive.strict.checks.orderby.no.limit 设置为 true 时，对于使用了 order by 语句的查询，要求必须使用 limit 语句。
		3）笛卡尔积
		将 hive.strict.checks.cartesian.product 设置为 true 时，会限制笛卡尔积的查询
	JVM 重用
	压缩
