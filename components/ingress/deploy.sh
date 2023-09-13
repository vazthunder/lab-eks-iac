#!/bin/bash -ex

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace -f values.yaml
