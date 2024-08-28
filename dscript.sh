#!/usr/bin/env bash

INDENT='    '

aws ec2 describe-regions --output text --query 'Regions[].[RegionName]' | sort -r |
  while read -r REGION; do

    export AWS_REGION="${REGION}"
    echo "* Region ${REGION}"

    # get default vpc
    vpc=$(aws ec2 describe-vpcs --filter Name=isDefault,Values=true --output text --query 'Vpcs[0].VpcId')
    if [ "${vpc}" = "None" ]; then
      echo "${INDENT}No default vpc found"
      continue
    fi
    echo "${INDENT}Found default vpc ${vpc}"

    # get internet gateway
    igw=$(aws ec2 describe-internet-gateways --filter Name=attachment.vpc-id,Values="${vpc}" --output text --query 'InternetGateways[0].InternetGatewayId')
    if [ "${igw}" != "None" ]; then
      echo "${INDENT}Detaching and deleting internet gateway ${igw}"
      aws ec2 detach-internet-gateway --internet-gateway-id "${igw}" --vpc-id "${vpc}"
      aws ec2 delete-internet-gateway --internet-gateway-id "${igw}"
    fi

    # get subnets
    subnets=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="${vpc}" --output text --query 'Subnets[].SubnetId')
    if [ "${subnets}" != "None" ]; then
      for subnet in ${subnets}; do
        echo "${INDENT}Deleting subnet ${subnet}"
        aws ec2 delete-subnet --subnet-id "${subnet}"
      done
    fi

    # delete default vpc
    echo "${INDENT}Deleting vpc ${vpc}"
    aws ec2 delete-vpc --vpc-id "${vpc}"

    # get default dhcp options
    dhcp=$(aws ec2 describe-dhcp-options --output text --query 'DhcpOptions[0].DhcpOptionsId')
    if [ "${dhcp}" != "None" ]; then
      echo "${INDENT}Deleting dhcp ${dhcp}"
      aws ec2 delete-dhcp-options --dhcp-options-id "${dhcp}"
    fi
  done
