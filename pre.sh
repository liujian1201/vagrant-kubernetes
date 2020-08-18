#!/bin/bash

#host
cat >> /etc/hosts <<EOF
172.17.8.101  node1
172.17.8.102  node2
172.17.8.103  node3
EOF

#timezone
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai
yum -y install ntpdate
ntpdate cn.pool.ntp.org

#firewalld
systemctl stop firewalld
systemctl disable firewalld

#selinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

#swapoff
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

#sysctl.conf
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF
sysctl -p /etc/sysctl.d/k8s.conf

#ipvs
#yum -y install ipset ipvsadm
#
#cat > /etc/sysconfig/modules/ipvs.modules <<EOF
##!/bin/bash
#modprobe -- ip_vs
#modprobe -- ip_vs_rr
#modprobe -- ip_vs_wrr
#modprobe -- ip_vs_sh
#modprobe -- nf_conntrack_ipv4
#EOF
#chmod 755 /etc/sysconfig/modules/ipvs.modules && \
#bash /etc/sysconfig/modules/ipvs.modules && \
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


#Docker  cgroups change systemd

yum install -y kubectl-1.18.6 kubeadm-1.18.6  kubelet-1.18.6
