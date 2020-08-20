#!/bin/bash

#添加主机名
cat >> /etc/hosts <<EOF
172.17.8.104  node1
172.17.8.105  node2
172.17.8.106  node3
EOF

#时间同步
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai
yum -y install ntpdate
ntpdate cn.pool.ntp.org

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

#关闭selinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

#关闭swap
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

#修改sysctl.conf
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF
sysctl -p /etc/sysctl.d/k8s.conf

#安装ipvs
yum -y install ipset ipvsadm

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && \
bash /etc/sysconfig/modules/ipvs.modules && \
#lsmod | grep -e ip_vs -e nf_conntrack_ipv4

#Docker
#yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

#K8s
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[Kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg 
EOF

yum makecache fast

yum install -y docker-ce-18.09.9-3.el7
systemctl enable docker
systemctl start docker

#修改Docker Cgroup Driver为systemd
cat > /etc/docker/daemon.json << EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
    "max-size": "100m"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ], 
    "registry-mirrors": [
        "https://kfwkfulq.mirror.aliyuncs.com",
        "https://2lqq34jg.mirror.aliyuncs.com",
        "https://pee6w651.mirror.aliyuncs.com",
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://registry.docker-cn.com"
    ]
}
EOF
#systemctl daemon-reload
systemctl restart docker

yum install -y kubectl-1.15.3 kubeadm-1.15.3  kubelet-1.15.3

#配置Kubernetes集群
#node1初始化master
#if [[ $1 -eq 4 ]]
#  then
#  kubeadm init --kubernetes-version=v1.15.3 --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers --apiserver-advertise-address=172.17.8.104 --pod-network-cidr=10.244.0.0/16 --service-cidr=10.1.0.0/16 --ignore-preflight-errors=NumCPU >>/root/kubeadm.log
#  join=`grep -E "kubeadm join.*--token.*" /root/kubeadm.log` 
##其他node加入
#else
#  echo $join|bash
#fi
