#！/bin/bash 
#此脚本用于将list.txt当中的库名输入到initOS.yaml 中，避免库比较多的情况下，手动手写比较麻烦
#######list.txt格式类似这样,除掉#号
#test1
#test2
#test3
##initOS.yaml中的格式类似这样
#
#mysqldb:
#  db1:
#    dbname: test
#    charset: utf8
#我最终的效果是要这样
#mysqldb:
#  db1:
#    dbname: test1
#    charset: utf8
#  db2:
#    dbname: test2
#    charset: utf8
#  db3:
#    dbname: test3
#    charset: utf8
i=0
while read line
do
let i++
	if [ $i -eq 1 ];then
		sed -i "s#dbname: test#dbname: $line#g" initOS.yaml
		continue
	fi
line_num=$(grep -nw "charset" initOS.yaml|tail -n1|awk -F ':' '{print $1}')
#sed -i "/charset: utf8/a db$i:" initOS.yaml
sed -i "$line_num a db$i:" initOS.yaml
	sed -i "s#db$i:#  db$i:#g" initOS.yaml
sed -i "/db$i:/a dbname: $line" initOS.yaml
	sed -i "s#dbname: $line#    dbname: $line#g" initOS.yaml
sed -i "/dbname: $line/a charset: utf8" initOS.yaml
	sed -i "s#^charset: utf8#    charset: utf8#g"         initOS.yaml
done<list.txt
