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

echo -e 'yes\n' | /kubesphere/kk create cluster -f config-sample.yaml
