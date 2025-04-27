#!/bin/bash

if [ -f ./credentials.auto.tfvars ]; then
    docker compose -f docker-compose.yml run --rm terraform $@
else
    echo "Setup credentials.auto.tfvars first"
fi