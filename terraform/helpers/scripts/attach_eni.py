import boto3
import sys
import time

if __name__ == '__main__':
    ec2_client = boto3.client('ec2')
    instance_id = sys.argv[1]
    env_name = sys.argv[2]
    eni_name = sys.argv[3]
    instance = boto3.resource('ec2').Instance(instance_id)
    eni = ec2_client.describe_network_interfaces(
            Filters=[
                {'Name': 'subnet-id', 'Values': [instance.subnet_id]},
                {'Name': 'tag:name', 'Values': [eni_name]},
                {'Name': 'tag:env_name', 'Values': [env_name]},
            ])['NetworkInterfaces'][0]
    eni_resource = boto3.resource('ec2').NetworkInterface(eni['NetworkInterfaceId'])
    if eni_resource.attachment and eni_resource.attachment.get('Status') == 'attached' \
            and eni_resource.attachment.get('InstanceId') != instance.id:
        try:
            eni_resource.detach(eni_resource.attachment.get('InstanceId'))
        except Exception as e:
            print('Failed to detach ... {}'.format(eni_resource.attachment))
            pass
    print('Attaching {}'.format(instance.id))
    eni_resource.attach(InstanceId=instance.id, DeviceIndex=1)
    while eni_resource.status != 'in-use':
        time.sleep(1)
        eni_resource = boto3.resource('ec2').NetworkInterface(eni['NetworkInterfaceId'])
    print('Attached.')

