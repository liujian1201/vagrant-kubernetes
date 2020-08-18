# vagrant 安装 kubernetes
- 基于macos，理论上其他平台没问题

## 需要先安装vagrant，VirtualBox
默认安装好预置环境，采用阿里源安装k8s组件

内存分配3G，1cpu，可以在vagrantfile进行修改

虚拟机启动起来后只需要在三台主机执行kubeadm命令，master需要加--ignore-preflight-errors=NumCPU

具体详情参考vagrantfile，pre.sh操作系统预置条件安装
