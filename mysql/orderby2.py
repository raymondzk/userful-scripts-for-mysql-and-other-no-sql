#/usr/bin/python
#coding=utf-8
#这个py文件用来测试生成order by数据表需要的数据
import threading
import mysql.connector
import random
import time



mysql_connect = mysql.connector.connect(
    host="10.0.0.17",
    user="appuser",
    password="123",
    database="test"
)


city_name_list = ['长沙', '武汉', '杭州', '苏州']

firstname_list = [

"赵","钱","孙","李","周","吴","郑","王","冯","陈","褚","卫","蒋","沈","韩","杨","朱","秦",
"尤","许","何","吕","施","张","孔","曹","严","华","金","魏","陶","姜","戚谢"
]


def set_lastname():
    head = random.randint(0xB0, 0xCF)
    body = random.randint(0xA, 0xF)
    tail = random.randint(0, 0xF)
    val = (head << 8) | (body << 4) | tail
    str = "%x" % val
    #return str.decode('hex').decode('gb2312')
    return  str.decode('hex').decode('gb2312','ignore')

cursor = mysql_connect.cursor()
cursor.execute('truncate table t')

num = 1
while num <= 10000:
    city_random_num = random.randint(0, len(city_name_list) - 1)
    city= city_name_list[city_random_num]
    #生成cityn ame
    firstname_random_num = random.randint(0, len(firstname_list) - 1)
    lastname = set_lastname()
    lastname = lastname.encode('utf-8','ignore')
    #将unicode转为str
    firstname = firstname_list[firstname_random_num]
    name = firstname + lastname
    #生成name
    age = random.randint(15, 50)
    sql = "insert into t(city,name,age) values('{}','{}','{}')".format(city,name,age)
    num = num + 1
    print(sql)
    cursor.execute(sql)
    mysql_connect.commit()

cursor.close()
mysql_connect.close
#关闭游标和数据库的连接