rm -rf /etc/docker/certs.d/harbor.dev.chenshaowen.com/ 
mkdir -p /etc/docker/certs.d/harbor.dev.chenshaowen.com/
mv ca.crt  harbor.dev.chenshaowen.com.cert harbor.dev.chenshaowen.com.key -t /etc/docker/certs.d/harbor.dev.chenshaowen.com/
