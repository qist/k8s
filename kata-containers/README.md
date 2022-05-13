# ansible 部署 kata-containers

```yaml
# ansible 版本 2.8 
# 部署方式  ansible-playbook -i 127.0.0.1, kata-containers.yml   127.0.0.1 需要部署的节点IP 多个IP 127.0.0.1,127.0.0.2, 
# 在centos 7,8 Ubuntu 18.04 19.04 进行测试完美运行
# 国内网络可以开启http 代理 修改roles\kata-containers\tasks\main.yml 默认注释掉 有自己的代理服务器请开启不然安装可能失败
- name: add  http_proxy  https_proxy
  lineinfile: 
    dest: ~/.bashrc
    line: '{{ item.key }}'
  with_items:
      - { key: 'export http_proxy=http://192.168.0.151:1081' }
      - { key: 'export https_proxy=http://192.168.0.151:1081' }
- name: Remove  http_proxy  https_proxy
  blockinfile:
    path: ~/.bashrc
    marker: '{{ item.key }}'
    block: ""
  with_items:
      - { key: 'export http_proxy=http://192.168.0.151:1081' }
      - { key: 'export https_proxy=http://192.168.0.151:1081' }
```
