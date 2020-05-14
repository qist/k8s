## ansible 部署  cri-o 及containerd 容器运行时
```
# ansible 版本 2.8 
# 下载地址 有些文件大小超过50M github 不能上传成功请大家自行下载
https://github.com/cri-o/cri-o/releases/download/v1.18.0/crio-v1.18.0.tar.gz
https://github.com/opencontainers/runc/releases/download/v1.0.0-rc10/runc.amd64
https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.18.0/crictl-v1.18.0-linux-amd64.tar.gz
https://github.com/containerd/containerd/releases/download/v1.3.4/containerd-1.3.4.linux-amd64.tar.gz
https://github.com/containernetworking/plugins/releases/download/v0.8.5/cni-plugins-linux-amd64-v0.8.5.tgz
# 部署方式  ansible-playbook -i 127.0.0.1, containerd.yml  或者 crio.yml 二选一 127.0.0.1 需要部署的节点IP 多个IP 127.0.0.1,127.0.0.2, 
# 在centos 7,8 Ubuntu 18.04 19.04 进行测试完美运行
# crio.yml containerd.yml 打开可以修改应用程序部署路径 CRIO_PATH: /apps  默认部署到 /apps
# kubelet 接入： 
# containerd 配置：
              --container-runtime=remote \
              --container-runtime-endpoint=unix:///run/containerd/containerd.sock \
              --containerd=unix:///run/containerd/containerd.sock \
# kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=containerd.service
Requires=containerd.service

[Service]
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/hugetlb/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/blkio/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/cpuset/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/devices/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/net_cls,net_prio/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/perf_event/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/cpu,cpuacct/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/freezer/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/memory/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/pids/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/systemd/systemd/system.slice
# 刷新service 并启动
systemctl daemon-reload
systemctl restart  kubelet.service 
cri-o 配置
       
              --container-runtime=remote \
              --container-runtime-endpoint=unix:///var/run/crio/crio.sock \
              --containerd=unix:///var/run/crio/crio.sock \   

# kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=crio.service
Requires=crio.service

[Service]
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/hugetlb/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/blkio/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/cpuset/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/devices/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/net_cls,net_prio/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/perf_event/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/cpu,cpuacct/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/freezer/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/memory/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/pids/systemd/system.slice
ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/systemd/systemd/system.slice  
# 刷新service 并启动
systemctl daemon-reload
systemctl restart  kubelet.service      
```