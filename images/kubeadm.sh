#!/bin/sh
set -e

# How to get the images list of specified K8s version？

# kubeadm init --config initconfig.yaml --dry-run
# sed -i -r "/kubernetesVersion: v/s#([0-9]{1,2}\.){2}[0-9]{1,2}#1.18.3#" initconfig.yaml
# kubeadm config images list --config initconfig.yaml

# There are two methods to get this images.

# for img in `kubeadm config images list --config initconfig.yaml`; do
#     docker pull "gcr.azk8s.cn/$(echo $img | tr '/' '_')" && docker tag "gcr.azk8s.cn/$(echo $img | tr '/' '_')" $img;
# done

# or sed -i "/imageRepository: /s#k8s.gcr.io#yourrepo#" initconfig.yaml

v1_18_3=(
  k8s.gcr.io/kube-apiserver:v1.18.3
  k8s.gcr.io/kube-controller-manager:v1.18.3
  k8s.gcr.io/kube-scheduler:v1.18.3
  k8s.gcr.io/kube-proxy:v1.18.3
  k8s.gcr.io/pause:3.1
  k8s.gcr.io/etcd:3.3.10
  k8s.gcr.io/coredns:1.3.1
)

v1_17_6=(
  k8s.gcr.io/kube-apiserver:v1.17.6
  k8s.gcr.io/kube-controller-manager:v1.17.6
  k8s.gcr.io/kube-scheduler:v1.17.6
  k8s.gcr.io/kube-proxy:v1.17.6
  k8s.gcr.io/pause:3.1
  k8s.gcr.io/etcd:3.3.10
  k8s.gcr.io/coredns:1.3.1
)

v1_16_10=(
  k8s.gcr.io/kube-apiserver:v1.16.10
  k8s.gcr.io/kube-controller-manager:v1.16.10
  k8s.gcr.io/kube-scheduler:v1.16.10
  k8s.gcr.io/kube-proxy:v1.16.10
  k8s.gcr.io/pause:3.1
  k8s.gcr.io/etcd:3.3.10
  k8s.gcr.io/coredns:1.3.1
)

v1_15_12=(
  k8s.gcr.io/kube-apiserver:v1.15.12
  k8s.gcr.io/kube-controller-manager:v1.15.12
  k8s.gcr.io/kube-scheduler:v1.15.12
  k8s.gcr.io/kube-proxy:v1.15.12
  k8s.gcr.io/pause:3.1
  k8s.gcr.io/etcd:3.3.10
  k8s.gcr.io/coredns:1.3.1
)

function src_to_dst {
  docker pull "${1}/${3}"
  docker tag "${1}/${3}" "${2}/${3}"
}

function retag_src_to_dst {
  if [[ $1 == v* ]];then
    src=$(eval echo "\${$1[*]}")
    dst=$2
    for i in ${src[@]}
    do
      IFS='/' read -r -a img <<< "$i"
      src_to_dst ${img[0]} ${dst} ${img[1]}
    done
  else
    src=$1
    dst=$(eval echo "\${$2[*]}")
    for i in ${dst[@]}
    do
      IFS='/' read -r -a img <<< "$i"
      src_to_dst ${src} ${img[0]} ${img[1]}
    done
  fi
}

retag_src_to_dst ${1} ${2}

# bash <(curl -s -L https://raw.githubusercontent.com/shaowenchen/scripts/master/images-mirror/kubeadm.sh) gcr.azk8s.cn/google_containers v1_18_3
# bash <(curl -s -L https://raw.githubusercontent.com/shaowenchen/scripts/master/images-mirror/kubeadm.sh) v1_18_3 gcr.azk8s.cn/google_containers
