#!/usr/bin/python
#coding=utf8
from multiprocessing import Process, Queue

ip_list = []
f = open('ip_list.txt','r')
while True:
    line = f.readline().rstrip("\n")
    if not line:
        break
    else:
        ip_list.append(line)


def ip_queue(q):
    for  ip in ip_list:
        q.put(ip)
q = Queue()

ip_queue(q)


for _ in range(q.qsize()):
    ip = q.get()
    print(ip)


