#!/bin/bash -ex

helm lint . -f values.yaml
helm upgrade -i myproj -f values.yaml -n myproj --create-namespace .
