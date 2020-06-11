os_info=`cat /etc/os-release`
if [[ $os_info =~ "Ubuntu" || $os_info =~ "Debian" ]]; then

    echo '
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse' > /etc/apt/sources.list

    rm -rf /var/lib/dpkg/lock
    apt-get clean
    apt-get update
    apt-get install -y python \
                       git \
                       vim \
                       sshpass

elif [[ $os_info =~ "CentOS" || $os_info =~ "Red Hat" ]]; then

    rm -rf /var/run/yum.pid
    yum install -y epel-release \
                   python \
                   git \
                   vim \
                   sshpass \
                   openssh-clients

else
    echo "It doesn't support the current operating system!"
fi

python <(curl -s -L https://bootstrap.pypa.io/get-pip.py)

pip install qingcloud-sdk==1.2.10
