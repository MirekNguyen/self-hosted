#!/usr/bin/env bash

curl -sfL https://get.k3s.io | sh - 
sudo cat /etc/rancher/k3s/k3s.yaml | grep certificate-authority-data
sudo cat /etc/rancher/k3s/k3s.yaml | grep client-certificate-data
sudo cat /etc/rancher/k3s/k3s.yaml | grep client-key-data
