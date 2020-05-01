FUsage(){

cat<<EOF
 从库搭建主从
./configure_check.sh --master_ip 10.0.0.17 --master_port 3306 --admin_password xxxx --repl_password xxxx -r slave

主库搭建主从
./configure_check.sh --master_ip 10.0.0.17 --master_port 3306 --admin_password xxxx --repl_password xxxx 

EOF
exit 
}
#ARGS=`getopt  -o h -al  master_port: -- "$@"`
#ARGS=`getopt -o p:host: -al master_port:,master_ip: -- "$@"`
ARGS=`getopt -o hr: -al master_port:,master_ip:,admin_password:,repl_password:,role: -- "$@"`

[ $? -ne 0 ] && FUsage
eval set -- "${ARGS}"
while true
do
case $1 in

        -h|--help)
            FUsage
	    break
            ;;
	
          --master_port)
	    master_port="$2" 
	    shift
            ;;


	  --master_ip)
            master_host="$2"
            shift
            ;;

	    --admin_password)
	        #action = "$2" && echo "$action"
		#shift

	    admin_password="$2" 

	    shift 
		;;
	     --repl_password)
	       repl_password=$2
	       shift
  		;;
             -r|--role)
	     role=$2	
	     ;;
		*)
		arg="$2"
		shift
		break
		;;	 

esac

shift 

done
cmd_local(){
/opt/mysql/bin/mysql -udbadmin -p$admin_password  -h127.0.0.1 -e "$1" 2>/dev/null
}

cmd_master(){

/opt/mysql/bin/mysql -udbadmin -p$admin_password  -h$master_host -P$master_port -e "$1" 2>/dev/null

}
#exit
#连接主库的命令

#exit

set_replication(){
check_repl_exist=$(cmd_local   "show slave status"|wc -l)

#该变量用来判断当前主从是否已经存在主从关系,0代表不存在主从关系

if [ $check_repl_exist  -eq 0    ];then
echo "正在搭建主从关系"
cmd_local   "reset master"
cmd_master    "reset master"
cmd_local  "CHANGE MASTER TO \
  MASTER_HOST='$master_host', \
  MASTER_USER='dbrepl', \
  MASTER_PASSWORD='$repl_password', \
  MASTER_PORT=3306, \
  MASTER_AUTO_POSITION=1, \
  MASTER_CONNECT_RETRY=10;"

cmd_local  "start slave"
else
echo "当前已经存在主从关系"
fi
###判断主从关系是否健康，在设置完以后

}
#该函数用来设置主从
check_replication_status(){
cmd_local  "show slave status\G"|egrep "Slave_IO_Running|Slave_SQL_Running:" 
}

report_check_replication_status(){
echo "主从关系检测"
check_repl_healthy=$(check_replication_status|grep -wci "yes" )
if [ $check_repl_healthy -eq 2 ];then
echo "主从关系从健康"
check_replication_status
else
echo "主从关系异常"
check_replication_status
fi

}

set_and_check_slave_read_only(){
if [ -n "$role" ];then
echo "当前实列为从库，检查read_only 是否等于ON"
read_only_judge=$(cmd_local "show variables like 'read_only';"|tail -n1 |awk '{print $2}')
echo $read_only_judge 
	if [[ $read_only_judge == "ON" ]];then
		echo  "当前实列为从库，已经配置read_only =ON"
		cmd_local "show variables like 'read_only';"
	else
	echo "当前实例为从库，正在配置read_only = ON"
	cmd_local "set global read_only = ON"
	read_only_judge=$(cmd_local "show variables like 'read_only';"|tail -n1 |awk '{print $2}')
	
		if [[ $read_only_judge == "ON" ]];then
			echo "当前实例为从库，已经配置read_only = ON"
			 cmd_local "show variables like 'read_only';"
		else
			echo  "配置配置read_only = ON失败"
		fi

	fi
else
echo "当前实列为主库，不需要设置read_only "
fi

}


 
set_and_check_slave_read_only_persistence(){
if [ -n "$role" ];then

        if [  `grep -cw "read_only" /etc/my.cnf` -eq 0   ];then
			echo "当前实例为从库，将设置read_only 到配置文件/etc/my.cnf当中"
                        echo "read_only=ON" >>/etc/my.cnf && grep "read_only" /etc/my.cnf
        else
                        echo  "当前实例为从库，read_only 已经持久化到配置文件当中"
                        grep "read_only" /etc/my.cnf

        fi

else
	echo "当前实例的角色为主库，无需设置read_only 到/etc/my.cnf"

fi

}


check_mount_point_persistence(){
echo "正在检查磁盘分区信息是否已经持久到/etc/fstab"
mount_point_judge=$(            grep -cw "/data/mysql" /etc/fstab          )

if [ $mount_point_judge  -eq  1 ];then
echo "磁盘分区信息已经持久化到/etc/fstab"
grep  "/data/mysql" /etc/fstab
else
echo   "磁盘分区信息没有持久化到/etc/fstab 请手动添加"
fi

}

set_replication
report_check_replication_status
set_and_check_slave_read_only
set_and_check_slave_read_only_persistence
check_mount_point_persistence
