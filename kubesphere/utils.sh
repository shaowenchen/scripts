function getInstaller(){
    echo '[Start getInstaller]'
    rm -rf /kubesphere
    mkdir /kubesphere
    cd /kubesphere
    curl -O -k https://kubernetes.pek3b.qingstor.com/tools/kubekey/kk
    chmod +x kk
    ./kk create config --with-kubesphere
    echo '[End getInstaller]'
}

function getKubespray(){
    echo '[Start getKubespray]'
    rm -rf /kubespray
    if [ $# != 1 ] ;then
       branch='master'
    else
       branch=$1
    fi
    cd /
    git clone https://github.com/kubernetes-sigs/kubespray.git -b ${branch}
    cd /kubespray
    echo '[End getKubespray]'
}

function chooseModule(){
    echo '[Start chooseModule]'

    sed -i "/enable_multi_login: /s#false#true#" $1

    for item in `env`
    do
        if [[ $item == *"_enabled"* ]]
        then
            echo $item
            IFS='=' read -r -a array <<< "$item"
            sed -i "/${array[0]}: /s#false#${array[1]}#" $1
        fi
    done
    echo '[End chooseModule]'
}

innerIp=
function getInnerIp(){
    echo '[Start getIp]'
    innerIp=$(sshpass  -p "$1" ssh -o StrictHostKeyChecking=no root@$2 "ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
    echo $innerIp
    echo '[End getIp]'
}

function setKsHostIni(){
    echo '[Start setKsHostIni]'
    if [ $QC_INNER_IP_1 ];then
	innerIp=$QC_INNER_IP_1
    else
        getInnerIp $QC_PASSWORD $QC_EIP_1
    fi
    sed -i "s/192.168.0.5/$innerIp/g" $1
    
    if [ $QC_INNER_IP_2 ];then
	innerIp=$QC_INNER_IP_2
    else
        getInnerIp $QC_PASSWORD $QC_EIP_2
    fi
    sed -i "s/192.168.0.6/$innerIp/g" $1
    
    if [ $QC_INNER_IP_3 ];then
	innerIp=$QC_INNER_IP_3
    else
        getInnerIp $QC_PASSWORD $QC_EIP_3
    fi
    sed -i "s/192.168.0.8/$innerIp/g" $1

    sed -i "s/Qcloud@123/$QC_PASSWORD/g" $1
    echo '[End setKsHostIni]'
}

function setQingcloudLb(){
    echo '[Start switchQingcloudLb]'
    sed -i "/qingcloud_access_key_id: /s#ACCESS_KEY_ID#${QC_ACCESS_KEY_ID}#" $1
    sed -i "/qingcloud_secret_access_key: /s#ACCESS_KEY_SECRET#${QC_SECRET_ACCESS_KEY}#" $1
    sed -i "/qingcloud_zone: /s#ZONE#${QC_ZONE}#" $1
    sed -i "/qingcloud_lb_enabled: /s#false#true#" $1
    sed -i "/qingcloud_vxnet_id: /s#SHOULD_BE_REPLACED#${QC_VXNET_ID}#" $1
    echo '[End switchQingcloudLb]'
}

function setNFS(){
    echo '[Start setNFS]'
    sed -i "/nfs_client_enabled: /s#false#true#" $1
    sed -i "/nfs_client_is_default_class: /s#false#true#" $1
    sed -i "/nfs_server: /s#SHOULD_BE_REPLACED#${2}#" $1
    sed -i "/nfs_path: /s#SHOULD_BE_REPLACED#${3}#" $1
    
    sed -i "/local_volume_enabled: /s#true#false#" $1
    echo '[End setNFS]'
}

function setLbApiserver(){
    sed -i "/port: 6443/aloadbalancer_apiserver:\n  address: $QC_HA_LB_IP\n  port: 6443" $1
}

function setKsHaHostIni(){
    echo '[Start setKsHaHostIni]'
    IFS=',' read -ra master_ip_list <<< "$QC_HA_MASTER_IPS"
    IFS=',' read -ra node_ip_list <<< "$QC_HA_NODE_IPS"

    echo '[all]
[kube-master]
[kube-node]
[etcd]
[k8s-cluster:children]
kube-node
kube-master' > $1

    if [ $QC_EXTRA_ETCD ] ;then
        IFS=',' read -ra extra_etcd_ip_list <<< "$QC_EXTRA_ETCD"

        for i in "${!extra_etcd_ip_list[@]}";
        do
        t_ip=${extra_etcd_ip_list[$i]}

        if [ $QC_USER ] ;then
        sed -i "/all]/a\\
        etcd${i}  ansible_host=${t_ip}  ip=${t_ip}  ansible_user=${QC_USER} ansible_ssh_pass=${QC_PASSWORD}" $1
        else
        sed -i "/all]/a\\
        etcd${i}  ansible_host=${t_ip}  ip=${t_ip}  ansible_ssh_pass=${QC_PASSWORD}" $1
        fi

        sed -i "/etcd]/a\\
        etcd${i}" $1

        done
    fi

    for i in "${!master_ip_list[@]}"; 
        do
        t_ip=${master_ip_list[$i]}

	    if [ $QC_USER ] ;then
        sed -i "/all]/a\\
        master${i}  ansible_host=${t_ip}  ip=${t_ip}  ansible_user=${QC_USER} ansible_ssh_pass=${QC_PASSWORD}" $1
        else
        sed -i "/all]/a\\
        master${i}  ansible_host=${t_ip}  ip=${t_ip}  ansible_ssh_pass=${QC_PASSWORD}" $1
        fi
	
        sed -i "/kube-master]/a\\
        master${i}" $1
        sed -i "/etcd]/a\\
        master${i}" $1
        done
    
    for i in "${!node_ip_list[@]}"; 
        do
        t_ip=${node_ip_list[$i]}
	
        if [ $QC_USER ] ;then
        sed -i "/all]/a\\
        node${i}  ansible_host=${t_ip}  ip=${t_ip}  ansible_user=${QC_USER}  ansible_ssh_pass=${QC_PASSWORD}" $1
        else
        sed -i "/all]/a\\
        node${i}  ansible_host=${t_ip}  ip=${t_ip}  ansible_ssh_pass=${QC_PASSWORD}" $1

        fi
	
        sed -i "/kube-node]/a\\
        node${i}" $1
        sed -i "/etcd]/a\\
        node${i}" $1
        done
    echo '[End setKsHaHostIni]'
}

function commitToGit(){
    echo '[Start commitToGit]'
    git clone -b $CI_COMMIT_REF_NAME $CI_REPOSITORY_URL git-dir
    cd git-dir
    cat ../$1 > $1
    git config --global user.email "auto@auto.com"
    git config --global user.name "auto"
    git add $1
    git commit -m "auto commit [ci skip]`git log -1 --pretty=%B`"
    git push $CI_REPOSITORY_URL $CI_COMMIT_REF_NAME >/dev/null || exit 0
    echo '[End commitToGit]'
}


function preDownloadImages(){
    echo '[Start preDownloadImages]'
    sleep 300
    docker version
    while [ $? -ne 0 ]; do
        sleep 60
        echo 'preDownloadImages waiting for docker'
        docker version
    done

    echo "preDownloadImages ing"
    cd /kubesphere/*/
    echo "- hosts: all
  vars_files:
    - preDownloadVars.yml
    - ../conf/common.yaml
  roles:
    - download
         " > kubesphere/preDownload.yml
    
    echo "docker_bin_dir: /usr/bin
retry_stagger: 5
         " > kubesphere/preDownloadVars.yml

    ansible-playbook -i $1 kubesphere/preDownload.yml

    echo '[End preDownloadImages]'
}
