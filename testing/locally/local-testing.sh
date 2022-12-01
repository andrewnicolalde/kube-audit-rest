#!/bin/bash

# set -eu

ROOT=$(git rev-parse --show-toplevel)

cd $ROOT

# Ensure local certs exist
testing/certs.sh

echo "Removing old test file"
rm -f tmp/kube-audit-rest.log;

echo "Removing old servers if still running"
pkill kube-audit-rest

# Run current server with those local certs on port 9090
go run . --cert-filename=./tmp/server.crt --cert-key-filename=./tmp/server.key --server-port=9090 --logger-filename=./tmp/kube-audit-rest.log &

sleep 5 # Scientific way of waiting for the server to be ready...

go run testing/locally/main.go

export TEST_EXIT="$?"

sleep 2 # Scientific way of waiting for the file to be written as async...

# Removing backgrounded process
pkill kube-audit-rest

diff testing/locally/data/kube-audit-rest.log tmp/kube-audit-rest.log && [ "$TEST_EXIT" -eq "0" ]&& echo "Test passed" || echo "output not as expected"