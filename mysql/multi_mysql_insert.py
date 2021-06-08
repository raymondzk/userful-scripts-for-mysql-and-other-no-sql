#!/usr/bin/python
#coding=utf-8
from multiprocessing import Pool
import os, time


def pro_do(process_num):
    #print("process_num is {}".format(process_num))
    print "child process id is %d" %(os.getpid())
    time.sleep(2)
    #time.sleep(6 - process_num)
    #os.system('python orderby.py')
    os.system('python t4.py')
    #os.system('python /tmp/orderby.py')
'''
def pro_do(process_num):
    print('hello {}'.format(i))
    time.sleep(6 - process_num)
    print "this is process %d" % (process_num)
'''
if __name__ == "__main__":
    print "Current process is %d" %(os.getpid())
    p = Pool(10)
    for i in range(10):
        p.apply_async(pro_do, (i,))  #增加新的进程
    p.close() # 禁止在增加新的进程
    p.join()
    p.terminate()
    print "pool process done"




