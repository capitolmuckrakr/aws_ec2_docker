#!/bin/bash -e
# You need to install the AWS Command Line Interface from http://aws.amazon.com/cli/

if [[ ! $PEM ]];
then
echo "Please make sure that a key is set in your shell's environment by entering 'export PEM=' followed by a path to a key you have chosen."
exit 0;
fi

source ./aws_ec2_param_functions.sh

#setting default parameters for the instance by calling param_functions, to override any function assign the corresponding env var
amiid
vpcid
subnetid
sgname

export PEMNAME=$(echo $PEM | rev | cut -d'/' -f1 | rev | sed -e 's/[^a-z]//g' | sed 's/pem//') #derive the keyname from the filename without the .pem extension

if [[ $profile ]];
then
export INSTANCEID=$(aws ec2 run-instances \
    --profile $profile \
    --image-id $AMIID \
    --key-name $PEMNAME \
    --instance-type $INSTANCETYPE \
    --security-group-ids $SGID \
    --subnet-id $SUBNETID \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":32,\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\"}}]" \
    --user-data file://aws_ec2_init_docker.sh \
    --query "Instances[0].InstanceId" \
    --output text)
else
export INSTANCEID=$(aws ec2 run-instances \
    --image-id $AMIID \
    --key-name $PEMNAME \
    --instance-type $INSTANCETYPE \
    --security-group-ids $SGID \
    --subnet-id $SUBNETID \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":32,\"DeleteOnTermination\":true,\"VolumeType\":\"gp2\"}}]" \
    --user-data file://aws_ec2_init_docker.sh \
    --query "Instances[0].InstanceId" \
    --output text)
fi

echo "waiting for $INSTANCEID ..."
if [[ $profile ]];
then
aws ec2 wait instance-running --profile $profile --instance-ids $INSTANCEID
else
aws ec2 wait instance-running --instance-ids $INSTANCEID
fi

if [[ $profile ]];
then
export ENDPOINT=$(aws ec2 describe-instances --profile $profile --instance-ids $INSTANCEID --query "Reservations[0].Instances[0].PublicDnsName" --output text)
else
export ENDPOINT=$(aws ec2 describe-instances --instance-ids $INSTANCEID --query "Reservations[0].Instances[0].PublicDnsName" --output text)
fi
sleep 30

#initialize_upload_files=''

if [[ $initialize_upload_files ]];
then
    counter=0
    scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i $PEM $initialize_upload_files ubuntu@$ENDPOINT:/home/ubuntu/
    upload_result=$?
    
    while [[ $? -ne 0 ]];
    do
    if [[ $counter -lt 3 ]];
    then
    sleep 5
    let counter+=1
    scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i $PEM $initialize_upload_files ubuntu@$ENDPOINT:/home/ubuntu/;
    upload_result=$?
    else
    echo "Failed 3 times to upload, exiting ..."
    exit 1
    fi
    done
fi
    . aws_ec2_functions.sh
echo "$INSTANCEID is accepting SSH connections under $ENDPOINT"
sleep 5

if [[ $initialize_upload_files ]];
then
    if [[ $upload_result -ne 0 ]];
    then
    sleep 5
    upload $initialize_upload_files
    fi
fi

exec $SHELL -i
