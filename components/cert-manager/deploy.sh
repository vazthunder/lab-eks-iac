#!/bin/bash -ex

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade -i cert-manager jetstack/cert-manager --set installCRDs=true -n cert-manager --create-namespace
