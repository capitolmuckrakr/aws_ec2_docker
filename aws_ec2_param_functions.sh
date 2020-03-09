#!/bin/bash -e
# You need to install the AWS Command Line Interface from http://aws.amazon.com/cli/

function amiid() { #select the most recent HVM image from the latest LTS version of Ubuntu if no image is assigned
    if [[ ! $AMIID ]];
    then
        AMIID=$(aws ec2 describe-images --filters "Name=name,Values=ubuntu/images/hvm-ssd*amd64*" "Name=description,Values=*LTS*" "Name=owner-id,Values=099720109477" --query 'reverse(sort_by(Images, &Description))[:1].ImageId' --output text)
        export AMIID
    fi
    echo $AMIID
    }

function vpcid() { #select the default VPC for the AWS account or profile if one is not assigned. Use an alternate IAM profile by assigning its id to the profile env var
    if [[ ! $VPCID ]];
    then
        if [[ ! $profile ]];
        then
            VPCID=$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)
        else
            VPCID=$(aws ec2 describe-vpcs --profile $profile --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)
        fi
        export VPCID
    fi
    echo $VPCID
    }

function subnetid() { #select the subnet for the AWS account or profile if one is not assigned. Use an alternate IAM profile by assigning its id to the profile env var
    if [[ ! $VPCID ]];
    then
        vpcid
    fi
    if [[ ! $SUBNETID ]];
    then
        if [[ ! $profile ]];
        then
            SUBNETID=$(aws ec2 describe-subnets --filters "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)
        else
            SUBNETID=$(aws ec2 describe-subnets --profile $profile --filters "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)
        fi
        export SUBNETID
    fi
    echo $SUBNETID
    }

function instancetypeoption() { #Use the t3a.micro instance if no type is assigned
    if [[ ! $INSTANCETYPE ]];
    then
        INSTANCETYPE='t3a.micro'
        export INSTANCETYPE
    fi
    echo $INSTANCETYPE
    }


function sgname() { #select or create a security group for the instance if one is not assigned.
    if [[ ! $VPCID ]];
    then
        vpcid
    fi
    if [[ ! $MY_CIDR ]];
    then
        OLDIFS=$IFS; IFS=. components=($(wget http://ipecho.net/plain -O - -q ; echo)); IFS=$OLDIFS
        MY_FIRST_IP=$(echo "${components[@]:0:3} 0/24")
        MY_CIDR=$(echo $MY_FIRST_IP | sed 's/ /\./g')
        export MY_CIDR
    fi
    if [[ ! $SGNAME ]];
    then
        SGNAME=dockersg
    fi
    if [[ ! $profile ]];
    then
        SGID=$(aws ec2 describe-security-groups --group-name $SGNAME --filters "Name=vpc-id, Values=$VPCID" --query "SecurityGroups[*].GroupId" --output text 2>/dev/null) #fetch an id if the group exists
        if [[ ! $SGID ]]; #create the group if no id (group doesn't exist yet)
        then
            SGID=$(aws ec2 create-security-group --group-name ${SGNAME} --description ${SGNAME} --vpc-id $VPCID --output text)
        fi
    else
        SGID=$(aws ec2 describe-security-groups --profile $profile --group-name $SGNAME --filters "Name=vpc-id, Values=$VPCID" --query "SecurityGroups[*].GroupId" --output text 2>/dev/null) #fetch an id if the group exists
        if [[ ! $SGID ]]; #create the group if no id (group doesn't exist yet)
        then
            SGID=$(aws ec2 create-security-group --profile $profile --group-name ${SGNAME} --description ${SGNAME} --vpc-id $VPCID --output text)
        fi
    fi
    export SGNAME
    export SGID
    if [[ ! $valid_ports ]];
    then
        valid_ports=( 22 )
    fi
    #make sure the firewall is open for the ports we want to access from our IP address
    for valid_port in "${valid_ports[@]}"
    do
        if [[ ! $profile ]];
        then
            aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port $valid_port --cidr $MY_CIDR 2>/dev/null
        else
            aws ec2 authorize-security-group-ingress --profile $profile --group-id $SGID --protocol tcp --port $valid_port --cidr $MY_CIDR 2>/dev/null
        fi
    done
    echo $SGNAME
    }


export -f amiid
export -f vpcid
export -f subnetid
export -f instancetypeoption
export -f sgname