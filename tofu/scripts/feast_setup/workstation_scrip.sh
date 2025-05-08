#!/bin/bash

CP=$(tofu output -json cp_public_ips | jq -r '.[0]')
CPHOST=${CP//./-}.nip.io

ssh -L 8001:localhost:8001 -i ~/.ssh/shumin-test.pem ubuntu@$CP


