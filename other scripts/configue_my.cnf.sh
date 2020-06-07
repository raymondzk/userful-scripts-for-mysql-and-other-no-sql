cnf='/etc/my.cnf'
time=$(date +%F)
cnf_bak=${cnf}_${time}

 if [ ! -f ${cnf_bak} ];then
	cp $cnf ${cnf_bak}
fi



while read line
do
variable_name=$(echo $line|awk -F '=' '{print $1}')

variable_judge=$(grep -wi "$variable_name" $cnf|wc -l)
str_judge=$(grep  "\[" /etc/my.cnf|tail -n1)
        #该变量用来判断配置文件例如/etc/my.cnf 中最后一个标签是不是[mysqld]

if [ $variable_judge -eq 0 ];then

#	sed --follow-symlinks -i "/mysqld/a $line " $cnf	




 	if [[ "$str_judge" == "[mysqld]" ]];then	
		str_info=$(grep "\#these variable changed on `date +%F`" /etc/my.cnf|wc -l)
		
	
		if  [ $str_info -eq 0 ];then

		echo "#these variable changed on `date +%F`" >>$cnf 

		fi	


		echo $line >>$cnf
	
	
		
	else
		str_info=$(grep "\#these variable changed on `date +%F`" /etc/my.cnf|wc -l)

		 str_judge_input=$(grep "\[" /etc/my.cnf|grep -C 1   '\[mysqld\]'|tail -n1|tr '[' ' '|tr ']' ' '|sed 's# ##g')


		if  [ $str_info -eq 0 ];then

                       sed -i --follow-symlinks "/\[$str_judge_input\]/i #these variable changed on `date +%F`" $cnf

                fi 



		sed -i --follow-symlinks "/\[$str_judge_input\]/i $line" $cnf


	fi




elif [ $variable_judge -eq 1  ];then

	variable_cnf=$(grep -wi "$variable_name" $cnf )

		sed -i  --follow-symlinks "s#$variable_cnf#$line#g" $cnf

elif [ $variable_judge -gt 1  ];then
	#variable_cnf_2=$()
	echo "$variable_name 在配置文件 $cnf 有多个，请手动修改" 

fi


done</tmp/variables_review.txt
