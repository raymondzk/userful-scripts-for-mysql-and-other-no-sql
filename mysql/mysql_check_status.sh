#!/bin/bash
###这个脚本用于MySQL的状态检查


process_check(){
process=$(ps -ef|grep -wc  [m]ysqld)
if [ $process -eq 0 ];then
	echo "当前服务器无MySQL进程,不存在任何MySQL实例,即将退出脚本"
	sleep 1 && exit 
fi

}



warning(){

echo "请输入以下菜单的编号进行操作:"

meminfo

}

jzjkusr(){
u=u
username='root'
password="I19S6fesMDcjCg!="
password_1=$(echo $password|base64 -d)
###MySQL的账号和密码，进行加密和解密
}




num_check(){
process_check
#process 判断mysqld的进程数量
port_num_all=$(ps -ef|grep -w [m]ysqld|egrep -oc 'port')
#第一种情况，只有一个MySQL进程，并且端口号就在进程里面,直接取出端口号
if [ "$port_num_all" == "$process" -a  $process -eq 1 ];then
port_name=$(ps -ef|grep [m]ysqld|egrep -o 'port\=[0-9]{1,5}'|awk -F '=' '{print $2}'|sort|tr '\n' ' ')
echo "当前服务器共存在$process个实例，端口号是$port_name"
port_count=1
#第二种情况,只有一个MySQL进程，但是端口号不在进程里面
fi

if [ $process -eq 1 -a $port_num_all -eq 0 ];then
check_port_name=$(netstat -lntp|netstat -lntp|grep -w mysqld|awk -F '[:]' '{print $4}'|wc -l)
	if [ $check_port_name -eq 1 ];then
		port_name=$(netstat -lntp|grep -w mysqld|awk -F '[:]' '{print $4}')	
		echo "当前服务器共存在$process个实例，端口号是$port_name"
		port_count=1
	else
	
		port_name=3306
		echo "当前服务器共存在$process个实例，端口号是$port_name"
		port_count=1
		fi
fi


#第三种情况,两个mysqld进程,端口号都在进程里面

if [ "$port_num_all" == "$process" -a  $process -eq 2  ];then
port_name=$(ps -ef|grep [m]ysqld|egrep -o 'port\=[0-9]{1,5}'|awk -F '=' '{print $2}'|sort|tr '\n' ' '| awk -v OFS="和" '{$1=$1;print $0}')

echo "当前服务器共存在$process个实例，端口号是$port_name"
port_count=2
fi 

#第四种情况，两个mysqld进程,端口号一个在进程里面,一个没在进程里面

if [ "$port_num_all" -lt "$process" -a $port_num_all -eq 1  ];then
port_name=$(ps -ef|grep [m]ysqld|egrep -o 'port\=[0-9]{1,5}'|awk -F '=' '{print $2}'|sort|tr '\n' ' '| awk -v OFS="和" '{$1=$1;print $0}')
	if [ $port_name -eq 3306 ];then
		port_name=$port_name:3307
		echo "当前服务器共存在$process个实例，端口号是$port_name"
                port_count=2
	else
		port_name=$port_name:3306
		echo "当前服务器共存在$process个实例，端口号是$port_name"
		port_count=2
	fi

	
fi

}

login_information(){
which mysql >/dev/null 2>&1
if [ $? -eq 0 ];then
 	login_command='mysql'
else
	login_command=$(ps -ef|grep -w [m]ysqld|head -n1|  -r 's#(.* )(.*)(d --defaults-file.*)#\2#g')
fi
jzjkusr
$login_command -$u $username -p$password_1  -h127.0.0.1 -P$port_name  2>/dev/null -e "$1"
}



login_as_dbadmin(){
num_check
if [ $port_count -ne 1 ];then
read -p "请问你想登陆哪个端口的数据库:" port_name	
echo "您正在登陆端口号为 $port_name的MySQL实例"
else
echo "您正在登陆端口号为 $port_name的MySQL实例"
fi

login_information
u=u
username='dbadmin'
echo "请输入用户为dbadmin密码"
sleep 1
$login_command -$u $username -p -P $port_name -h 127.0.0.1
echo "正在退出脚本,继续使用脚本,请重新执行脚本"
sleep 0.5
exit
}


#version_check(){
#jzjkusr
#version_name=$(login_information "select version()"|grep -vi "version()")
#if
#	[[ $version_name =~ ^5.6.*  ]];then
#		version_name_num=5.6
#elif	
#
#	[[ $version_name =~ ^5.7.*  ]];then
#        	version_name_num=5.7
#elif
#
#	[[ $version_name =~ ^5.5.*  ]];then
#       		 version_name_num=5.5
#
#
#fi
#
#}
#version_check

Check_master_slave_status(){

process_check
num_check
jzjkusr
login_information

#1、这段判断当前服务器上的MySQL实例是否存在主从关系,如果不存在主从关系就会跳过查看主从关系的步骤,继续打印菜单

if [ $port_count -ne 1 ];then
read -p "请问你想查看哪个端口MySQL的主从复制信息:" port_name
echo "您正在查看端口为$port_name MySQL的主从复制信息 "
judge_slave_exist=$(login_information "show slave status\G"|grep -cw "Slave_IO_Running:")
	if [ $judge_slave_exist -eq 0 ];then

        	echo "你所选择的$port端口的MySQL实例没有主从复制信息,请使用其它帮助选项!"  
        	meminfo
        	continue
	fi
else

echo "您正在查看端口为$port_name MySQL的主从复制信息 "
judge_slave_exist=$(login_information "show slave status\G"|grep -cw "Slave_IO_Running:")
        if [ $judge_slave_exist -eq 0 ];then

                echo "你所选择的$port端口的MySQL实例没有主从复制信息,请使用其它帮助选项!"  
                meminfo
                continue
        fi


fi



check_master_slave_status(){
status_num=$(login_information "show slave status $1  \G"|egrep "Slave_IO_Running:|Slave_SQL_Running"|grep -wci "yes")
io_status=$(login_information "show slave status $1 \G"|grep "Slave_IO_Running"|grep -cwi "yes")
sqlthread_status=$(login_information "show slave status $1 \G"|grep "Slave_SQL_Running"|grep -cwi "yes")
slave_delay_status=$(login_information "show slave status $1 \G"|grep "Seconds_Behind_Master")
slave_delay_status=500
total_num_io_slave_thread=$(login_information "show slave status $1 \G"|egrep -cw "Slave_SQL_Running:|Slave_IO_Running:")






if [[ "$status_num" == $total_num_io_slave_thread ]];then
       echo "当前主从关系正常"
		#login_information "show slave status  $1  \G"|egrep "Slave_IO_Running|Slave_SQL_Running:$2"
elif [ $io_status -ne 1 ];then

       echo "当前主从关系不正常,从库I/O线程报错,报错原因如下"

       login_information "show slave status  $1   \G"|egrep "Last_IO_Errno|Last_IO_Error$2"



elif  [ $sqlthread_status -ne 1 ];then

       echo "当前主从关系不正常,从库SQL线程报错,报错原因如下:" 

       login_information "show slave status $1   \G"|egrep "Last_SQL_Errno|Last_SQL_Error$2 "



elif  [ $status_num -eq 2 -a $slave_delay_status -gt 500 ];then

        echo "当前主从关系正常但主从延迟较为严重,延迟了$slave_delay_status秒" 
       login_information "show slave status $1 \G"|egrep "Seconds_Behind_Master:$2"

       
fi


}





#login_information "show slave status\G"|egrep "Slave_IO_Running|Slave_SQL_Running:"
judge_chanel_exist=$(login_information "show slave status\G"|grep -w "Channel_Name:"|awk '{print $2}'|grep -v "^$"|wc -l)
judge_master_num=$(login_information  "show slave status\G"|grep -cw "Slave_IO_Running:")
channel_name=$(login_information "show slave status\G"|grep -w "Channel_Name:"|awk '{print $2}'|grep -v "^$")
#第1种情况,如果judge_chanel_exist为0,并且judge_master_num为1，证明当前MySQL实例主从关系,但是没有定义chanel,并且当前库只对应一个主库
if [ $judge_chanel_exist -eq 0  -a  $judge_master_num -eq 1  ];then
	echo "您正在查看端口为$port_name的MySQL实例的主从复制状态"
	sleep 0.5
	check_master_slave_status
		

elif [ $judge_chanel_exist -eq 1  -a  $judge_master_num -eq 1 ];then

	echo "您正在查看端口为$port_name的MySQL实例channel_name为$channel_name的主从复制状态"
	sleep 0.5
	check_master_slave_status "for channel '$channel_name'" "|Channel_Name:"
elif  [ $judge_chanel_exist -gt 1  ];then
        all_chanel_name=$(login_information "show slave status\G"|grep -w "Channel_Name:"|awk '{print $2}'|tr '\n' ' '| awk -v OFS="和" '{$1=$1;print $0}')
	echo -e "端口为$port_name的MySQL实例存在$judge_master_num个主从复制关系,对应的复制名称是$all_chanel_name:\n如果想查看单独复制关系,请输入相应的复制名称,如果想查看全部的复制关系,请输入 all "
	read -p "请输入相应的复制关系查询名称:"	channel_name
        	if [[ "$channel_name" == "all" ]];then
			echo "您正在查看端口为$port_name的MySQL实例所有的主从复制状态"	
			sleep 0.5
			check_master_slave_status  "    "   "|Channel_Name:"
		else
			echo "您正在查看端口为$port_name的MySQL实例channel_name为$channel_name的主从复制状态"
			sleep 0.5
			check_master_slave_status "for channel '$channel_name'"  "|Channel_Name:"

		fi

fi


}

session_information(){
num_check
jzjkusr
if [ $port_count -ne 1 ];then
read -p "请问你想查询端哪个端口的MySQL实例的会话信息:" port_name
echo "您正在查询端口为 $port_name的MySQL实例的会话信息"
else
echo "您正在查询端口为 $port_name的MySQL实例的会话信息"
fi

login_information "show processlist"
}

full_session_information(){
num_check
jzjkusr
if [ $port_count -ne 1 ];then
read -p "请问你想查询哪个端口MySQL实例的完整会话信息:" port_name
echo "您正在查询端口为 $port_name的MySQL实例的完整会话信息"
else
echo "您正在查询端口为 $port_name的MySQL实例的完整会话信息"
fi
login_information "select * from information_schema.PROCESSLIST order by ID;"
}

active_session_information(){
num_check
if [ $port_count -ne 1 ];then
read -p "请问你想查询哪个端口MySQL实例的活跃会话信息:" port_name
echo "您正在查询端口为 $port_name的MySQL实例的活跃会话信息"
else
echo "您正在查询端口为 $port_name的MySQL实例的活跃会话信息"
fi
login_information "select * from information_schema.PROCESSLIST  where COMMAND != 'Sleep' order by ID "
}

kill_session(){
num_check

kill_session_as_dbadmin(){
read -p "请问您想杀死哪个会话，请输入Id号:" Id
echo "正在杀死会话Id为$Id的会话,请稍候"
u=u
username='dbadmin'
echo "请输入用户为dbadmin密码"
$login_command -$u $username -p -P $port_name -h 127.0.0.1  2>/dev/null -e  "kill $Id"
#judge_session_killed=$(login_information "show full  processlist"|grep $Id|wc -l)

        if [ $? -eq 0  ];then
		sleep 3
                echo "杀死会话Id为$Id成功,重新为您查询端口为 $port_name的MySQL实例的会话信息"
		login_information "select * from information_schema.PROCESSLIST order by ID;"
        else
		sleep 3
                echo "杀死会话Id为$Id失败,重新为您查询端口为 $port_name的MySQL实例的会话信息"
		login_information "select * from information_schema.PROCESSLIST order by ID;"
        fi



}


if [ $port_count -ne 1 ];then
read -p "请问你杀死哪个端口MySQL实例的话信息:" port_name
echo "正在查询端口为 $port_name的MySQL实例的会话信息"
jzjkusr
sleep 1
login_information "select * from information_schema.PROCESSLIST order by ID;"
kill_session_as_dbadmin
else
echo "正在查询端口为 $port_name的MySQL实例的会话信息"
jzjkusr
sleep 1
login_information "select * from information_schema.PROCESSLIST order by ID;"
kill_session_as_dbadmin

fi


}











lock_information_get(){
num_check
jzjkusr
if [ $port_count -ne 1 ];then
read -p "请问你想查询哪个端口MySQL实例的的锁信息:" port_name
echo "您正在查询端口为 $port_name的MySQL实例的锁信息"
else
echo "您正在查询端口为 $port_name的MySQL实例的锁信息"
fi



#version_check(){
#jzjkusr


#lock_information_get
version_name=$(login_information "select version()"|grep -vi "version()")

echo $version_name
if
        [[ $version_name =~ ^5.6.*  ]];then
                version_name_num=5.6
elif

        [[ $version_name =~ ^5.7.*  ]];then
                version_name_num=5.7
elif

        [[ $version_name =~ ^5.5.*  ]];then
                 version_name_num=5.5


fi

#}
#version_name_num=5.7

judge_lock_check=$(login_information "select * from information_schema.INNODB_LOCK_WAITS;"|wc -l)

	if [ $judge_lock_check -eq 0 ];then

		echo "你所查询端口为 $port_name的MySQL实例当前没有锁信息"
	else
		echo "你所查询端口为 $port_name的MySQL实例当前有下列锁信息,请查看"

			if [[ $version_name_num == 5.7 ]];then

	                        login_information "select information_schema.innodb_trx.trx_query as '被锁语句' ,

sys.innodb_lock_waits.waiting_pid as '被锁语句ID',

performance_schema.threads.PROCESSLIST_ID as '锁源ID',

sys.innodb_lock_waits.locked_table as '被锁表'

from information_schema.innodb_trx join   sys.innodb_lock_waits on information_schema.innodb_trx.trx_mysql_thread_id=sys.innodb_lock_waits.waiting_pid

join performance_schema.threads on sys.innodb_lock_waits.blocking_pid=performance_schema.threads.PROCESSLIST_ID

join performance_schema.events_statements_current

on performance_schema.threads. THREAD_ID=

performance_schema.events_statements_current.THREAD_ID;"
 

			elif [[ $version_name_num ==  5.6  ]];then
				login_information "select a.trx_query as '被锁语句' , a.trx_mysql_thread_id as '被锁语ID',c.trx_mysql_thread_id
as '锁源ID'
from information_schema.innodb_trx as a 
join information_schema.INNODB_LOCK_WAITS as b
on a.trx_id=b.requesting_trx_id
join information_schema.innodb_trx as c 
on b.blocking_trx_id=c.trx_id;"
			

			elif [[ $version_name_num ==  5.5  ]];then

				login_information   "select * from information_schema.innodb_lock_waits"
			
			fi			


			

	fi



}






meminfo(){
cat <<-EOF
--------------------------------
|    1) 查看本机MySQL信息       |
|    2) 查看主从信息            |
|    3) 查看MySQL会话信息       |
|    4) 查看MySQL完整会话信息   |
|    5) 查看MySQL活跃的会话信息 |
|    6) 杀死指定的MySQL会话信息 |
|    7) 查看MySQL锁信息         |
|    8) 登陆MySQL               |
|    h) 帮助                    |
|    e) 退出                    |
---------------------------------
EOF
}
meminfo

while true
do
        read -p "请输入需要操作的编号,如果忘记操作编号，请输入h:" num
        case $num in 
                1)
                        process_check
                        sleep 1
			num_check
                        ;;
                2)
			Check_master_slave_status
                        ;;
                3)
                        session_information
                        ;;
                4)      
			full_session_information
                        
                        ;;
                5)     
			active_session_information

                        ;;
                6)  
                       	kill_session
                	;;   
                7)
			lock_information_get
			;;
		8)
			login_as_dbadmin
		
			;;
			
                h)  	meminfo                                        
			;;
                  
                e)
                        break
                        ;;
                *)
			echo "请输入菜单上的标号"
			warning
		
        esac
done


