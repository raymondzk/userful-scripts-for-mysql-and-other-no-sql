#!/bin/bash


FUsage(){
  cat <<EOF
    no options     start all 3rd's applications
    --help         show the help information
    -h             show the help information
    -p             set the mongodb port name you want to start
    -a             set the action for the mongodb (start, stop, status, restart)
    USAGE : 
    Example:
            bash mongodb.sh  --help
            bash mongodb_start_stop.sh -p 28017 -a [start|stop|restart]"	
	    bash mongodb_start_stop.sh -p all   -a [start|stop|restart]
	    bash mongodb_start_stop.sh -p 28017,28019   -a [start|stop|restart]
EOF

}

ARGS=`getopt  -o hp:a: -- "$@"`
[ $? -ne 0 ] && FUsage
eval set -- "${ARGS}"
while true
do
case $1 in

        -h|--help)
            FUsage
	    break
            ;;
	
          -p)
	    port_name="$2" 
	    shift
            ;;

	    -a)
	        #action = "$2" && echo "$action"
		#shift

	    action="$2" 

	    shift 
		;;

		*)
		arg="$2"
		shift
		break
		;;	 

esac

shift 

done
#echo $port_name && exit
cmd_file=/data/mongodb/28017/bin/mongod
#cmd_file represents mongod the absolute path,it's a start command,you can define it



if [ -z $port_name ];then
option_file=/data/mongodb/28017/conf/mongodb.conf
fi


Start(){
for each_port_num in `echo $port_name|tr ',' ' '`
do
option_file=/data/mongodb/$each_port_num/conf/mongodb.conf

pidfile=/data/mongodb/$each_port_num/log/$each_port_num.pid


	$cmd_file -f $option_file >/dev/null
	




done
}

###$each_port_num represent the mongodb port which need to start
###like 28017 need to start or 28017,28018 both need to start
##each_port_num depend on the user need which port need to start
#option_file represent the configuration file that  mongodb instance need to start
#if need to start 28017 port,the configuation file is /data/mongodb/28017/conf/mongodb.conf
#if you don't define the which port to start,the script will need to start 28017 port mongodb(default)
Start_all(){	
	for option_file_all in `ls /data/mongodb/`
	do
	$cmd_file -f /data/mongodb/$option_file_all/conf/mongodb.conf
	sleep 0.5
	done
}

#Start_all function defines a function when you need to start all mongodb  port on this machine 

Stop_all(){

        for option_file_all in `ls /data/mongodb/`
        do
        $cmd_file -f /data/mongodb/$option_file_all/conf/mongodb.conf   --shutdown
        sleep 0.5
        done

}

#Stop_all function defines a function when you need to stop all mongodb port on this machine



Check_status_all(){

for port_num in `ls /data/mongodb`
do

port_process=$(ps -ef|grep -cw "[/]data/mongodb/$port_num/conf")
if [ $port_process -eq 1 ];then
echo "port:$port_num is running"
else
echo "port:$port_num is not running"

fi

done


}


Stop(){
for each_port_num in `echo $port_name|tr ',' ' '`
do
option_file=/data/mongodb/$each_port_num/conf/mongodb.conf
$cmd_file -f $option_file  --shutdown
done
}


#Status(){
#status_num=$(ps -ef|grep -w "[/]data/mongodb"|grep -cw "$1")
#if [ $status_num -ge 1 ];then
#
#echo "port:$port_name  mongodb is running"
#
#else
#
#echo "port:$port_name is not running"
#
#fi
#
#
#}

Check_status(){

for each_port_num in `echo $port_name|tr ',' ' '`
do

each_port_process=$(ps -ef|grep -cw "[/]data/mongodb/$each_port_num/conf")
	if [ $each_port_process -eq 1 ];then

		echo "port:$each_port_num is running"
	else

		echo "port:$each_port_num is not running"	
	
	fi

done


}


Restart(){
Stop
sleep 1
Start
}


Restart_all(){
Stop_all
sleep 0.5
Start_all
}




case $action in 
	start)
		if [[ $port_name == "all" ]];then
			Start_all
		else
                		Start	

		fi
	;;
        stop)
		#Stop
                if [[ $port_name == "all" ]];then
                        Stop_all
                        #echo "1"
                else
                                Stop

                fi

	;;
	
	restart)
		     if [[ $port_name == "all" ]];then
                             Restart_all
                     else

                             Restart

                     fi 
	;;
	status)
		#Status $port_name


                if [[ $port_name == "all" ]];then
                        Check_status_all
                else
                                Check_status 

                fi





	;;
		
	*)
	
		FUsage
	;;
esac
