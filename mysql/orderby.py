#/usr/bin/python
#coding=utf-8

import threading
import pymysql
import random
import time
from multiprocessing import Pool
import os, time

class mysql_opreate():
    def __init__(self):
        try:
            self.mysql_connect = pymysql.connect(
                host="10.0.0.17",
                user="root",
                password="123",
                database="test",
                charset = "utf8")
            self.mysql_connect.autocommit(1)
        except Exception as e:
            print("连接数据库异常，请查看连接信息是否正确{}").format(e)
            quit()
        else:
            self.cursor = self.mysql_connect.cursor()

    def execute_sql(self,sql):
        try:
            self.cursor.execute(sql)

        except Exception as e:
            print("传入的sql语句有问题,请查看错误及sql语句 {} {}").format(e,sql)

        return 'ok'

    def select_sql(self,sql):
        try:
            self.cursor.execute(sql)
        except Exception as e:
            print("传入的sql语句有问题,请查看错误及sql语句 {} {}").format(e,sql)
        else:
            return self.cursor.fetchall()

    def __del__(self):
        self.cursor.close()
        self.mysql_connect.close()

    def close_mysql(self):
        self.cursor.close()
        self.mysql_connect.close()



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
    return  str.decode('hex').decode('gb2312','ignore')


def sql_info():
    city_random_num = random.randint(0, len(city_name_list) - 1)
    city = city_name_list[city_random_num]
    firstname_random_num = random.randint(0, len(firstname_list) - 1)
    lastname = set_lastname()
    lastname = lastname.encode('utf-8', 'ignore')
    firstname = firstname_list[firstname_random_num]
    name = firstname + lastname
    age = random.randint(15, 50)
    sql = "insert into t(city,name,age) values('{}','{}','{}')".format(city, name, age)
    return  sql

zk = mysql_opreate()
zk.execute_sql('truncate table t')
#zk.execute_sql('drop table if exists t')
#zk.execute_sql("CREATE TABLE `t` (   `id` int(11) NOT NULL auto_increment,   `city` varchar(16) NOT NULL,   `name` varchar(16) NOT NULL,   `age` int(11) NOT NULL,   PRIMARY KEY (`id`),   KEY `city` (`city`) ) ENGINE=InnoDB;")

def execute_sql(sql_text):
    print "child process id is %d" %(os.getpid())
    #time.sleep(1)
    zk.execute_sql(sql_text)


while True:
    sql_text= sql_info()
    zk.execute_sql(sql_text)




''''
if __name__ == "__main__":
    print "Current process is %d" %(os.getpid())
    p = Pool(3)

    for i in range(100):
        sql_value = sql_info()
        p.apply_async(execute_sql, (sql_value,))  #增加新的进程
    p.close() # 禁止在增加新的进程
    p.join()
    p.terminate()
    print "pool process done"
    #zk.close_mysql()
'''






'''
num = 0
while num <=5:
    sql_text= sql_info()
    zk.execute_sql(sql_text)
    num = num + 1
'''




