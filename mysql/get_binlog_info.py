#!/usr/bin/python
#coding=utf-8
import time
import argparse
import subprocess
import os
import re
import  linecache
def print_help_info():
    print('''
    #目前该脚本用于分析mysql binlog中大事务，长事务（需要自行传递--transaction_time 参数）及每个表的增删改查情况
    #该脚本目前只测试过binlog格式为row,gtid模式下的相关信息统计，具体参数用法执行-h,以下为该脚本的4种用法
    #查看mysql 是否开启binlog_rows_query_log_events 的值，若为off请加上参数-binlog_rows_query_log_events off
    1、python get_binlog_info.py -transaction_size 20M --start_position 4 --stop_position 1000 --binlog_file mysql-bin.000001
    #根据起始位置点截取binlog分析
    2、python get_binlog_info.py -transaction_size 20M --start_position 4 --binlog_file mysql-bin.000001
    #根据start_position开始位置点分析，一直到结尾
    3、python get_binlog_info.py -transaction_size 20M  - --start-datetime  "2020-10-21 17:49:00"  --stop-datetime "2020-10-21 21:15:00" --binlog_file mysql-bin.000001
    #根据起始时间点进行分析
    4、python get_binlog_info.py -transaction_size 20M  --binlog_file mysql-bin.000001
    #直接分析整个binlog
    #如果不想统计归档日志中每个表的dml次数，请添加--dml_total_count=off
    #如果想统计归档日志中长事务，请添加--transaction_time 秒 例如想确认归档日志中是否有运行时间超过1000秒的事务
    #--transaction_time  1000
    式例:
    1、若binlog_rows_query_log_events 参数值为off，想查询事务大小超过5M的大事务，binlog文件名为mysql-bin.000007的binlog，用以下参数
    python get_binlog_info.py -binlog_file /data/mysql/binlog/mysql-bin.000007  -transaction_size 5M  -binlog_rows_query_log_events off
    2、若binlog_rows_query_log_events 参数值为on,想查询事务大小超过5M的大事务，binlog文件名为mysql-bin.000007的binlog，用以下参数
    python get_binlog_info.py -binlog_file /data/mysql/binlog/mysql-bin.000007  -transaction_size 5M
    
    ''')
    quit()

def unix_timestamp(beijing_time):
    unixtime_format = int(time.mktime(time.strptime(beijing_time, '%Y%m%d %H:%M:%S')))
    return unixtime_format


parser = argparse.ArgumentParser()
parser.add_argument('-binlog_file', "--binlog_file", help="specify the binlog file")
parser.add_argument('-transaction_size', "--transaction_size", help="specify the big transaction size")
parser.add_argument('-binlog_rows_query_log_events', "--binlog_rows_query_log_events", help="specify the big transaction size",default='on')
parser.add_argument('-start_position', "--start_position")
parser.add_argument('-stop_position', "--stop_position")
parser.add_argument('-dest_path', "--dest_path",default="/tmp",help="the result file dicotry path,default is /tmp")
parser.add_argument('-start_datetime','--start_datetime',help="specify the start time,for example --start_datetime  '2020-10-21 17:49:00'")
parser.add_argument('-stop_datetime','--stop_datetime',help="specify the stop time,for example --stop_datetime  '2020-10-21 21:00:00'")
parser.add_argument('-dml_total_count','--dml_total_count',help="to pass a parameter to judge if need to count dml operation",default="on")
parser.add_argument('-transaction_time','--transaction_time',help="to pass a parameter to judge if need to get long transaction ")


args = parser.parse_args()

binlog_file = args.binlog_file
if binlog_file == None:
    print_help_info()
else:
    binlog_file = args.binlog_file
transaction_size = args.transaction_size
if transaction_size == None:
    print_help_info()
else:
    transaction_size = transaction_size.replace('M','')
transaction_size = int(transaction_size)
transaction_size = transaction_size * 1024
binlog_query = args.binlog_rows_query_log_events
start_position = args.start_position
stop_position = args.stop_position
dest_path = args.dest_path
now_time = time.strftime("%Y_%m_%d_%H", time.localtime())
binlog_temp_file = dest_path + "/binlog" + "_" + now_time
start_time = args.start_datetime
stop_time = args.stop_datetime
dml_total_count = args.dml_total_count
transaction_time = args.transaction_time

if not os.path.isfile(binlog_temp_file):
    pass
else:
    binlog_temp_file = dest_path + "/binlog" + "_" + time.strftime("%Y_%m_%d_%H_%M", time.localtime())

if start_time == None and  stop_time == None:
    if start_position == None and  stop_position == None:
        mysqlbinlog_command =  "mysqlbinlog -vv  --base64-output=decode-rows  {} |egrep -v \"^SET @@session|^SET TIMESTAMP|^/\*\" >{}".format(
        binlog_file, binlog_temp_file)

    elif stop_position == None:
        mysqlbinlog_command = "mysqlbinlog -vv  --base64-output=decode-rows  --start-position {}  {} |egrep -v \"^SET @@session|^SET TIMESTAMP|^/\*\" >{}".format(
            start_position, binlog_file, binlog_temp_file)

    else:
        mysqlbinlog_command = "mysqlbinlog -vv  --base64-output=decode-rows --start-position {}  --stop-position  {} {} |egrep -v \"^SET @@session|^SET TIMESTAMP|^/\*\">{}".format(
            start_position, stop_position, binlog_file, binlog_temp_file)


else:
    mysqlbinlog_command = "mysqlbinlog -vv  --base64-output=decode-rows  --start-datetime '{}' --stop-datetime '{}' {} |egrep -v \"^SET @@session|^SET TIMESTAMP|^/\*\">{}".format(
        start_time, stop_time,binlog_file,binlog_temp_file)

# binlog_decode_output_cmd = "mysqlbinlog -vv --base64-output=decode-rows {}|egrep -v \"^SET @@session|^SET TIMESTAMP|^/\*\" >{}".format(binlog_file,binlog_temp_file)


if binlog_file == None or transaction_size == "None":
    print("you must pass binlog_file or  transaction_size")
    print_help_info()
    quit()


def shell_cmd_function(cmd,timeout = 300):
    shell_cmd = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                shell=True)
    start_time = time.time()
    while True:

        # print('start_time is{}'.format(start_time))
        shell_cmd.poll()
        # print('code is {}'.format(shell_cmd.returncode))
        if shell_cmd.returncode == 0:
            return shell_cmd.stdout.read().strip()

        if shell_cmd.returncode is None:
            now_time = time.time()
            # print('3')
            time_period = now_time - start_time
            if time_period > timeout:
                print('timeout is {} reached,please check linux command:{}'.format(timeout,cmd))
                quit()
        else:
            return shell_cmd.stderr.read().strip()

def shell_cmd_function_with_return_code(cmd,timeout = 120):
    shell_cmd = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                shell=True)
    start_time = time.time()
    while True:

        # print('start_time is{}'.format(start_time))
        shell_cmd.poll()
        # print('code is {}'.format(shell_cmd.returncode))
        if shell_cmd.returncode == 0:
            return shell_cmd.returncode
        if shell_cmd.returncode is None:
            now_time = time.time()
            # print('3')
            time_period = now_time - start_time
            if time_period > timeout:
                print('timeout is {} reached,please check linux command:{}'.format(timeout,cmd))
                quit()
        else:
            return shell_cmd.returncode

mysqlbinlog_cmd_judge = shell_cmd_function_with_return_code("which mysqlbinlog")
if mysqlbinlog_cmd_judge != 0:
    print("could not find mysqlbinlog command,please use which mysqlbinlog command to check")
    quit()




try:
    shell_cmd_function_with_return_code(mysqlbinlog_command)
except Exception as decode_binlog_error:
    print(decode_binlog_error)
    quit()
else:
    print("mysqlbinlog decode binlogfile {} to temporay file {} sucessfully ".format(binlog_file,binlog_temp_file))


file_name = binlog_temp_file

f = open(file_name,'r')
line_num = 0
gtid_mode = 'on'
binlog_format = "row"
dml_total_count= dml_total_count
transaction_size = transaction_size
start_position = 0
stop_position = 0
gtid_info = 0
sql_info = 0
commit_num = 0
start_time = 0
table_list = []
insert_dic = {}
update_dic = {}
delete_dic = {}
dml_dic = {}


def dml_count(table_name):
    if table_name not in dml_dic:
        dml_dic[table_name] = 1
    else:
        new_value = int(dml_dic[table_name]) + 1
        dml_dic[table_name] = new_value

def table_operation_count(line):
    if line.startswith('### INSERT INTO'):
        line = line.lstrip("### ").strip()
        table_name = re.findall(r"INSERT INTO (.*)", line)
        table_name = str(table_name)
        table_name = table_name.replace('`', '')
        table_name = table_name.replace('[', '')
        table_name = table_name.replace(']', '')
        table_name = table_name.replace("'", '')
        # print(table_list)
        if table_name not in table_list:
            table_list.append(table_name)
        else:
            pass
        # print(table_list)
        if table_name not in insert_dic:
            insert_dic[table_name] = 1
        else:
            new_value = int(insert_dic[table_name]) + 1
            insert_dic[table_name] = new_value
        dml_count(table_name)

    if line.startswith('### UPDATE'):
        line = line.lstrip("### ").strip()
        table_name = re.findall(r"UPDATE (.*)", line)
        table_name = str(table_name)
        table_name = table_name.replace('`', '')
        table_name = table_name.replace('[', '')
        table_name = table_name.replace(']', '')
        table_name = table_name.replace("'", '')
        if table_name not in table_list:
            table_list.append(table_name)
        # print(table_list)
        if table_name not in update_dic:
            update_dic[table_name] = 1
        else:
            new_value = int(update_dic[table_name]) + 1
            update_dic[table_name] = new_value
        dml_count(table_name)

    if line.startswith('### DELETE'):
        line = line.lstrip("### ").strip()
        table_name = re.findall(r"DELETE FROM (.*)", line)
        table_name = str(table_name)
        table_name = table_name.replace('`', '')
        table_name = table_name.replace('[', '')
        table_name = table_name.replace(']', '')
        table_name = table_name.replace("'", '')
        if table_name not in table_list:
            table_list.append(table_name)
        # print(table_list)
        if table_name not in delete_dic:
            delete_dic[table_name] = 1
        else:
            new_value = int(delete_dic[table_name]) + 1
            delete_dic[table_name] = new_value
        dml_count(table_name)




while True:
    line_num = line_num + 1
    # print(line_num)
    line = f.readline()

    if re.search("BEGIN",line):
        start_position = linecache.getline(file_name,line_num - 2)
        start_position = str(start_position[5:])
        start_position = int(start_position)
        start_time = linecache.getline(file_name,line_num - 1)
        start_time = start_time[1:16]
        start_time = "20" + start_time
        start_time = unix_timestamp(start_time)
        if binlog_query == "on":
            sql_info = linecache.getline(file_name,line_num + 3 )
        if gtid_mode == "on":
            gtid_info = linecache.getline(file_name,line_num - 3 )
            gtid_info = gtid_info.strip()
    if binlog_format =="row" and dml_total_count == "on":
        table_operation_count(line)
    if line[: 6] == 'COMMIT':
        # print("line_num is line_num {}".format(line_num))
        stop_position = linecache.getline(file_name,line_num - 2)
        stop_position = str(stop_position[5:])
        stop_position = int(stop_position)
        stop_time = linecache.getline(file_name,line_num - 1)
        stop_time = stop_time[1:16]
        stop_time = "20" + stop_time
        stop_time = unix_timestamp(stop_time)

        # print("stop_position is {}".format(stop_position))
        # print("transize is {}".format(transaction_size))
        if int(stop_position) - int(start_position) >= transaction_size:
            transaction_actully_size = int(stop_position) - int(start_position)
            print("start_position is {} # stop_position is {} # transaction_actully_size is {}".format(start_position,stop_position,transaction_actully_size))
            if gtid_mode == "on":
                print("gtid num is {}".format(gtid_info))
            if binlog_query == "on":
                print(sql_info)
            else:
                pass

        if transaction_time != None:
            if stop_time - start_time  >= transaction_time:
                print("long transaction info,please see above info")
    if not line:
        break

f.close()

print("this binary log file total contains these tables:%s" %(table_list))
print("every table insert operation count:%s"%(insert_dic))
print("every table update operation count:%s"%(update_dic))
print("every table delete operation count:%s"%(delete_dic))
print("every table delete dml count:%s"%(dml_dic))
os.remove(binlog_temp_file)