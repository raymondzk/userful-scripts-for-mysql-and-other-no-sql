#!/usr/bin/python
#coding=utf8
import subprocess
import time
from multiprocessing import Process, Queue
from multiprocessing.pool import Pool
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


ip_list = []
f = open('ip_list.txt','r')
while True:
    line = f.readline().rstrip("\n")
    if not line:
        break
    else:
        ip_list.append(line)

#将所需要测试ip 放入列表ip_list 中


'''
from multiprocessing import Process, Queue

def f(q):
    q.put([42, None, 'hello'])

if __name__ == '__main__':
    q = Queue()
    p = Process(target=f, args=(q,))
    p.start()
    print(q.get())    # prints "[42, None, 'hello']"
    p.join()

# 队列是线程和进程安全的

'''


def ip_queue(q):
    for  ip in ip_list:
        q.put(ip)

def ping_ip(ip):
    ip_command = "ping -c 3" + ' '+ ip
    print(ip)
    time.sleep(4)
    ping_result = shell_cmd_function_with_return_code(ip_command)
    # print("ip is {}".format(ip))
    if ping_result != 0:
        print("ip is %s could not reached "%(ip))



if __name__ == "__main__":
    p = Pool(4)
# 创建4个进程的进程池，同时只能运行4个进程
    q = Queue()
    ip_queue(q)
    for _ in range(q.qsize()):
        ip = q.get()
        p.apply_async(ping_ip, args=(ip,))
    p.close()
    p.join()
    print("ip ping task finised")
    p.terminate()



