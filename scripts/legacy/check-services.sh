#!/bin/bash
# Script to check the status of media server services

echo "Checking Samba status..."
systemctl status smbd --no-pager

echo -e "\nChecking NFS status..."
systemctl status nfs-server --no-pager

echo -e "\nListing Samba shares..."
smbclient -L localhost -N

echo -e "\nListing NFS exports..."
showmount -e localhost

echo -e "\nChecking mounted drives..."
df -h /media/joe/*
