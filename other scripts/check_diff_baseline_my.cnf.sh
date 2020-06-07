>/tmp/zk.txt
sed -i '/BIND_ADDRESS/d' variable.txt
while read line
do
cmd='mysql -uroot -p123 -S /data/3307/mysql.sock'
$cmd -e "select VARIABLE_NAME,VARIABLE_VALUE from information_schema.global_variables where VARIABLE_NAME='$'" 2>/dev/null|tail -n1
line=$(echo $line|awk '{print $1,$2}')
variable_1=$(echo $line|awk '{print $1}')
value_1=$(echo $line|awk '{print $2}')

variable_2=$($cmd -e "select VARIABLE_NAME,VARIABLE_VALUE from information_schema.global_variables where VARIABLE_NAME='$variable_1'" 2>/dev/null|tail -n1|awk '{print $1}')
variable_2_num=$($cmd -e "select VARIABLE_NAME,VARIABLE_VALUE from information_schema.global_variables where VARIABLE_NAME='$variable_1'" 2>/dev/null|tail -n1|wc -l)
values_2=$($cmd -e "select VARIABLE_NAME,VARIABLE_VALUE from information_schema.global_variables where VARIABLE_NAME='$variable_1'" 2>/dev/null|tail -n1|awk '{print $2}')




if [ $variable_2_num -eq 0 ];then

	echo "$variable_1" "$value_1" `hostname` "上的MySQL实例不存在该参数"  >>/tmp/zk.txt
elif [[ "$value_1"   !=   "$values_2"    ]];then
	echo "$variable_1" "$value_1" "与" `hostname`  "$variable_2" "$values_2" "不一样" >>/tmp/zk.txt



fi
done</tmp/variable.txt
