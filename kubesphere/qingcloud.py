import time
import os
import sys


import qingcloud.iaas as qc
from qingcloud.iaas.actions.eip import EipAction


zone = os.environ.get('QC_ZONE', '')
access_key_id = os.environ.get('QC_ACCESS_KEY_ID', '')
secret_access_key = os.environ.get('QC_SECRET_ACCESS_KEY', '')

eip_id = os.environ.get('QC_EIP_ID')
vxnet_id = os.environ.get('QC_VXNET_ID')
security_group_id = os.environ.get('QC_SECURITY_GROUP_ID')

passwd = os.environ.get('QC_PASSWORD', 'Qcloud@123')
login_mode = os.environ.get('QC_LOGIN_MODE', 'passwd')
login_keypair = os.environ.get('QC_LOGIN_KEYPAIR', '')

instance_name = os.environ.get('QC_INSTANCE_NAME', 'auto')
cpu = 1 * int(os.environ.get('QC_CPU', '8'))
memory = 1024 * int(os.environ.get('QC_MEMORY', '16'))
image_id = os.environ.get('QC_IMAGE_ID', 'centos75x64b')
disk_size = os.environ.get('QC_DISK_SIZE', '100')

data_filename = os.environ.get('QC_DATA_FILENAME', 'db.txt')
wanted_num = int(os.environ.get('QC_EXPECTED_NUM', '3'))


def createInstance(conn, image_id, cpu, memory, vxnets, security_group,
                   login_mode=login_mode,
                   login_passwd=passwd,
                   os_disk_size=disk_size,
                   instance_name=instance_name):
    return conn.run_instances(
        image_id=image_id,
        cpu=cpu,
        memory=memory,
        vxnets=vxnets,
        login_mode=login_mode,
        login_passwd=login_passwd,
        os_disk_size=os_disk_size,
        security_group=security_group,
        instance_name=instance_name)


def resetInstance(conn, instance_id_list):
    print("[Ready To Reset: %s]" % instance_id_list)
    body = {'instances': instance_id_list,
            'login_mode': login_mode,
            'login_passwd': passwd,
            'login_keypair': login_keypair}
    return conn.send_request("ResetInstances", body)


def deleteInstance(conn, instance_id_list):
    print("[Ready To Delete: %s]" % instance_id_list)
    return conn.terminate_instances(instance_id_list)


def addEip(conn, instance_id):
    eip = EipAction(conn)
    body = {'eip': eip_id, 'instance': instance_id}
    return eip.conn.send_request("AssociateEip", body)


def freeEip(conn, eip_id):
    eip = EipAction(conn)
    body = {'eips': [eip_id]}
    return eip.conn.send_request("DissociateEips", body)


def updateInstanceData(filename,
                       instance_list,
                       wanted_num):
    new_instance_list = instance_list[:]
    if os.path.exists(filename):
        with open(filename) as reader:
            for line_num, line_content in enumerate(reader):
                new_instance_list.extend(line_content.split(','))
                break
    print("[All Instance List: %s]" % new_instance_list)
    with open(filename, "w+") as writer:
        writer.write(','.join(new_instance_list[:wanted_num]))
    return new_instance_list[wanted_num:]


def createMode(conn):
    instance_info = createInstance(conn, image_id, cpu, memory,
                                   [vxnet_id], security_group_id)
    delete_list = updateInstanceData(data_filename,
                                     instance_info.get('instances', []),
                                     wanted_num)
    print(instance_info)
    print(freeEip(conn, eip_id))
    time.sleep(20)
    print(addEip(conn, eip_id, instance_info['instances'][0]))

    for item in delete_list:
        print("[Delete Instance Result: %s[" % deleteInstance(conn, [item]))


def resetMode(conn, instance_id_list):
    for item in instance_id_list:
        print(resetInstance([item], passwd))


if __name__ == "__main__":
    conn = qc.connect_to_zone(
        zone,
        access_key_id,
        secret_access_key
        )
    if len(sys.argv) > 1:
        print("Reset Mode: %s" % str(sys.argv))
        if ',' in sys.argv[1]:
            resetid_list = sys.argv[1].split(',')
        else:
            resetid_list = sys.argv[1:]
        resetInstance(conn, resetid_list)

    else:
        print("Create Mode: %s" % str(sys.argv))
        createMode(conn)
