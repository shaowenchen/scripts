curl -s -L https://raw.githubusercontent.com/shaowenchen/scripts/master/kubesphere/preinstall.sh | bash

source <(curl -s https://raw.githubusercontent.com/shaowenchen/scripts/master/kubesphere/utils.sh)

for i in $*
do
  if [[ $i == *"="* ]]
  then
    echo $i
    IFS='=' read -r -a array <<< "$i"
    export ${array[0]}=${array[1]}
  fi
done

getInstaller

chooseModule /kubesphere/config-sample.yaml

setKsHaHostIni /kubesphere/*/conf/hosts.ini

setQingcloudLb /kubesphere/config-sample.yaml

setLbApiserver /kubesphere/config-sample.yamlaml

if [ $QC_NFS_IP ];then
  echo '[start]install nfs server'
  setNFS /kubesphere/config-sample.yaml $QC_NFS_IP /ksdata
  sshpass  -p "$QC_PASSWORD" ssh -o StrictHostKeyChecking=no root@$QC_NFS_IP "yum install -y nfs-utils & mkdir /ksdata/ & echo '/ksdata/  *(rw,sync,no_root_squash,no_all_squash)' > /etc/exports"
  sshpass  -p "$QC_PASSWORD" ssh -o StrictHostKeyChecking=no root@$QC_NFS_IP "service nfs-server start"
  echo '[end]install nfs server'
fi

echo -e 'yes\n' | /kubesphere/kk create cluster -f config-sample.yaml
