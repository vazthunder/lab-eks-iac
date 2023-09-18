#!/bin/bash -ex

helm upgrade -i karpenter oci://public.ecr.aws/karpenter/karpenter -f values.yaml -n karpenter --create-namespace --version "v0.30.0"
