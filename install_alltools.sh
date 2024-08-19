#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "请以root身份运行此脚本"
  exit
fi

apt update

echo "更换为清华大学镜像源..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak
UBUNTU_VERSION=$(lsb_release -cs)
cat > /etc/apt/sources.list << EOL
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_VERSION main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_VERSION-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_VERSION-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_VERSION-security main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $UBUNTU_VERSION-proposed main restricted universe multiverse
EOL
apt update
echo "清华大学镜像源更换完成。"

echo "安装开发工具（gcc, g++, make, vim, git, OpenSSH, stress-ng, ipmitool）..."
apt install -y gcc g++ make vim git openssh-server stress-ng ipmitool
systemctl start ssh
systemctl enable ssh
echo "开发工具安装完成。"

echo "安装Anaconda3..."
ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-2023.03-Linux-x86_64.sh"
wget $ANACONDA_URL -O anaconda.sh
bash anaconda.sh -b -p $HOME/anaconda3
eval "$($HOME/anaconda3/bin/conda shell.bash hook)"
conda init
source ~/.bashrc
echo "Anaconda3安装完成。"

echo "安装CUDA..."
CUDA_REPO_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin"
wget $CUDA_REPO_URL
mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub
add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /"
apt update
apt install -y cuda-11-8
echo 'export PATH=/usr/local/cuda-11.8/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
echo "CUDA安装完成。"

echo "安装cuDNN..."
CUDNN_TAR_FILE="cudnn-11.8-linux-x64-v8.1.1.33.tgz"
CUDNN_URL="https://developer.download.nvidia.com/compute/redist/cudnn/v8.1.1/$CUDNN_TAR_FILE"
wget $CUDNN_URL
tar -xzvf $CUDNN_TAR_FILE
cp -P cuda/include/cudnn*.h /usr/local/cuda-11.8/include
cp -P cuda/lib64/libcudnn* /usr/local/cuda-11.8/lib64/
chmod a+r /usr/local/cuda-11.8/include/cudnn*.h /usr/local/cuda-11.8/lib64/libcudnn*
echo "cuDNN安装完成。"

echo "安装并编译GPU Burn..."
apt install -y git
git clone https://github.com/wilicc/gpu-burn.git
cd gpu-burn
make
cp gpu_burn /usr/local/bin/
cd ..
rm -rf gpu-burn
echo "GPU Burn安装并编译完成。"

echo "已安装的软件版本："
gcc --version
g++ --version
make --version
vim --version
git --version
ssh -V
conda --version
nvcc --version
stress-ng --version
ipmitool --version

echo "所有软件安装完成并已配置环境变量。请重新登录以应用更改。"