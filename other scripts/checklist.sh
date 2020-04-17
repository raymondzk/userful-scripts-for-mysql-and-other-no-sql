> /tmp/list_all_temp.txt
>/tmp/list_all.txt
list_all=$(ls -l /tmp/|grep "list.txt_"|awk '{print $NF}')
for list_each in $list_all
do
cat $list_each >>/tmp/list_all_temp.txt
done

cat list_all_temp.txt|sort -k 1 >list_all.txt
> /tmp/result.txt




while read line
do
column_3=$(echo $line|awk '{print $3}'|tr '[' ' '|tr ']' ' '|tr '{' ' ')
#该变量主要定义取出第三列，也就是表名和库名和存储引擎
column_total_num_3=$(echo $column_3|egrep -o "engine"|wc -l)
#知道有多少个表的数量
column_1=$(echo $line|awk '{print $1}')
column_2=$(echo $line|awk '{print $2}')


	i=1
	column_total_num_3=$column_total_num_3
	while [ $column_total_num_3 -ne 0 ];
        do
	column_part_3=$(echo $column_3|awk -v a=$i -F '},' '{print $a}'|tr ']' ' ')	
		echo $column_1 $column_2 $column_part_3 >>/tmp/result.txt
	#column_total_num_3=`$column_total_num_3-1`
	let column_total_num_3--
	let i++
	done

#第一次i=1,$3_column_total_num =3 3_column_part 取第三列的第一列，
#第二次i=2,$3_column_total_num =2,$3_column_total_num 取第三列的第2列
#第三次i=3,$3_column_total_num =1,$3_column_total_num 取第三列的第3列
##第四次,$3_column_total_num =0,跳出循环




done<list_all.txt


