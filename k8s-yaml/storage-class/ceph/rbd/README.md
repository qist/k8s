# rbd storageClass 部署
```
# centos8 ceph rpm 包下载
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/babeltrace-1.5.4-2.el8.x86_64.rpm               
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/ceph-base-14.2.4-5.el8cp.x86_64.rpm             
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/ceph-common-14.2.4-5.el8cp.x86_64.rpm          
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/ceph-osd-14.2.4-5.el8cp.x86_64.rpm             
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/ceph-selinux-14.2.4-5.el8cp.x86_64.rpm         
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/ceph-test-14.2.4-5.el8cp.x86_64.rpm            
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/gperftools-libs-2.6.3-2.el8+7.x86_64.rpm       
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/leveldb-1.20-1.el8+7.x86_64.rpm                
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/libcephfs-devel-14.2.4-5.el8cp.x86_64.rpm      
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/libcephfs2-14.2.4-5.el8cp.x86_64.rpm           
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/liboath-2.6.1-5.el8+5.x86_64.rpm               
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/librados-devel-14.2.4-5.el8cp.x86_64.rpm       
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/librados2-14.2.4-5.el8cp.x86_64.rpm            
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/libradospp-devel-14.2.4-5.el8cp.x86_64.rpm     
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/libradosstriper1-14.2.4-5.el8cp.x86_64.rpm     
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/librbd-devel-14.2.4-5.el8cp.x86_64.rpm         
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/librbd1-14.2.4-5.el8cp.x86_64.rpm              
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/librgw-devel-14.2.4-5.el8cp.x86_64.rpm         
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/librgw2-14.2.4-5.el8cp.x86_64.rpm              
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/libunwind-1.2.1-5.el8.x86_64.rpm               
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/lttng-ust-2.8.1-11.el8.x86_64.rpm              
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/python3-ceph-argparse-14.2.4-5.el8cp.x86_64.rpm
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/python3-cephfs-14.2.4-5.el8cp.x86_64.rpm       
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/python3-rados-14.2.4-5.el8cp.x86_64.rpm        
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/python3-rbd-14.2.4-5.el8cp.x86_64.rpm          
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/python3-rgw-14.2.4-5.el8cp.x86_64.rpm          
ftp://partners.redhat.com/cea2c9e6481d3de81578640349d9b6dc/rhel-8/OSD/x86_64/os/Packages/xmlstarlet-1.6.1-10.el8+7.x86_64.rpm           
rpm -ivh *.rpm --nodeps --force
#进入ceph 创建存储空间
ceph osd pool ls
#创建 pool
ceph osd pool create kube 50
#创建授权ceph
ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube' -o kube.keyring
#测试kube.keyring 是否 可用
ceph -n client.kube --keyring=kube.keyring health
#[root@ceph-adm ~]# ceph -n client.kube --keyring=kube.keyring health
HEALTH_OK
ceph -n client.kube --keyring=kube.keyring osd pool ls
#[root@ceph-adm ~]# ceph -n client.kube --keyring=kube.keyring osd pool ls
rbd
kube
#获取key base64
client.admin
ceph auth get-key client.admin | base64
#[root@ceph-adm ~]# ceph auth get-key client.admin | base64
QVFDcCtybGFsaU9XTGhBQWoyZTI1NUd1ZU9SSnl4NXpUeHFrWVE9PQ==
client.kube
ceph auth get-key client.kube | base64
#[root@ceph-adm ~]# ceph auth get-key client.kube | base64
QVFDMTY5ZGN1a2dETWhBQVpDY2hOQ09mY1lwWGZXMU5HRU4wSGc9PQ==
# 修改 secrets.yaml 改成自己获取值
# 修改class.yaml 改成自己ceph mon 地址
# 部署rbd storageClass kubectl apply -f .
# 测试 能自己创建pvc 并成功写入文件 kubectl apply -f test/.
```
