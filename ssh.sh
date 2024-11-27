#!/bin/sh
public_ip=$(terraform output -raw public_ip)
ssh ubuntu@"$public_ip" -i .ssh/tf-cloud-init
