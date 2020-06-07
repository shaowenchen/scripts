rm -rf /etc/docker/certs.d/core.harbor.dev.chenshaowen.com/ 
mkdir -p /etc/docker/certs.d/core.harbor.dev.chenshaowen.com/
mv ca.crt  harbor.dev.chenshaowen.com.cert harbor.dev.chenshaowen.com.key -t /etc/docker/certs.d/core.harbor.dev.chenshaowen.com/