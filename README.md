# docker でのマルチキャスト利用例

マルチキャストを利用したモニタリングツール「[Ganglia Monitoring System](http://ganglia.info/)」を利用。


## 構成図

出来上がる ganglia クラスタの構成図

![構成図](https://docs.google.com/drawings/d/1_f5ELCqYA-4yqfe0GCYtbmT-fuoLofkmR8jJQBvwBGE/pub?w=452&h=378 "構成図")

## 実行ログ

```console

[mapk0y@kona:~/ganglia-cluster]$ # 2台だけクラスタを起動
[mapk0y@kona:~/ganglia-cluster]$ docker-compose up -d
Creating gangliacluster_server_1
Creating gangliacluster_master_1

[mapk0y@kona:~/ganglia-cluster]$ # 状態の確認
[mapk0y@kona:~/ganglia-cluster]$ docker-compose ps
         Name                        Command               State   Ports 
------------------------------------------------------------------------
gangliacluster_master_1   /usr/sbin/gmond -c /etc/ga ...   Up            
gangliacluster_server_1   /usr/sbin/gmond -c /etc/ga ...   Up            

[mapk0y@kona:~/ganglia-cluster]$ # ganglia のクラスタステータスの確認ツール gstat で確認（ホストがマスターを合わせて2台見える）
[mapk0y@kona:~/ganglia-cluster]$ docker-compose exec master gstat
CLUSTER INFORMATION
       Name: Example
      Hosts: 2
Gexec Hosts: 2
 Dead Hosts: 0
  Localtime: Tue Dec 13 17:49:29 2016

CLUSTER HOSTS
Hostname                     LOAD                       CPU              Gexec
 CPUs (Procs/Total) [     1,     5, 15min] [  User,  Nice, System, Idle, Wio]

gangliacluster_server_1.gangliacluster_default
    4 (    0/    0) [  0.00,  0.00,  0.00] [   0.1,   0.0,   0.1,  99.7,   0.0] ON
2ac8ea2500f2
    4 (    0/    0) [  0.00,  0.00,  0.00] [   0.1,   0.0,   0.1,  99.7,   0.0] ON


[mapk0y@kona:~/ganglia-cluster]$ # docker-compose の機能で "server" を合計5台に変更
[mapk0y@kona:~/ganglia-cluster]$ docker-compose scale server=5
Creating and starting gangliacluster_server_2 ... done
Creating and starting gangliacluster_server_3 ... done
Creating and starting gangliacluster_server_4 ... done
Creating and starting gangliacluster_server_5 ... done

[mapk0y@kona:~/ganglia-cluster]$ # ganglia のクラスタステータスの確認ツール gstat で確認（ホストがマスターを合わせて6台見える）
[mapk0y@kona:~/ganglia-cluster]$ docker-compose exec master gstat
CLUSTER INFORMATION
       Name: Example
      Hosts: 5
Gexec Hosts: 5
 Dead Hosts: 0
  Localtime: Tue Dec 13 17:49:54 2016

CLUSTER HOSTS
Hostname                     LOAD                       CPU              Gexec
 CPUs (Procs/Total) [     1,     5, 15min] [  User,  Nice, System, Idle, Wio]

gangliacluster_server_3.gangliacluster_default
    4 (    0/    0) [  0.00,  0.00,  0.00] [   0.1,   0.0,   0.1,  99.7,   0.0] ON
gangliacluster_server_4.gangliacluster_default
    4 (    0/    0) [  0.00,  0.00,  0.00] [   0.1,   0.0,   0.1,  99.7,   0.0] ON
gangliacluster_server_5.gangliacluster_default
    4 (    0/    0) [  0.00,  0.00,  0.00] [   0.1,   0.0,   0.1,  99.7,   0.0] ON
gangliacluster_server_1.gangliacluster_default
    4 (    0/    0) [  0.00,  0.00,  0.00] [   0.1,   0.0,   0.1,  99.7,   0.0] ON
2ac8ea2500f2
    4 (    0/    0) [  0.00,  0.00,  0.00] [  23.4,   0.0,   2.6,  73.9,   0.0] ON


[mapk0y@kona:~/ganglia-cluster]$ # それぞれのコンテナでマルチキャストアドレスにjoinしていることを確認
[mapk0y@kona:~/ganglia-cluster]$ # 127.0.0.11 はdockerが自動的に用意する内部DNS
[mapk0y@kona:~/ganglia-cluster]$ docker-compose exec master ss -autn
Netid State   Recv-Q Send-Q  Local Address:Port   Peer Address:Port 
udp   ESTAB   0      0          172.23.0.2:38180   239.2.11.71:8649  
udp   UNCONN  0      0         239.2.11.71:8649              *:*     
udp   UNCONN  0      0          127.0.0.11:50229             *:*     
tcp   LISTEN  0      5                   *:8649              *:*     
tcp   LISTEN  0      128        127.0.0.11:45013             *:*     
[mapk0y@kona:~/ganglia-cluster]$ docker-compose exec --index=1 server ss -autn
Netid State   Recv-Q Send-Q  Local Address:Port   Peer Address:Port 
udp   UNCONN  0      0         239.2.11.71:8649              *:*     
udp   ESTAB   0      0          172.23.0.3:42321   239.2.11.71:8649  
udp   UNCONN  0      0          127.0.0.11:51724             *:*     
tcp   LISTEN  0      128        127.0.0.11:33919             *:*     
[mapk0y@kona:~/ganglia-cluster]$
Netid State   Recv-Q Send-Q  Local Address:Port   Peer Address:Port 
udp   UNCONN  0      0          127.0.0.11:41303             *:*     
udp   UNCONN  0      0         239.2.11.71:8649              *:*     
udp   ESTAB   0      0          172.23.0.6:43284   239.2.11.71:8649  
```

## 問題点

現在の設定だと ganglia が CPU をいっぱい使ってしまう...
