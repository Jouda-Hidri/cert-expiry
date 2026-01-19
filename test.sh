#!/bin/bash


output=$(bash ./argo_external_ssl_check.sh ./valid_cert.yaml)
if [ ! -f "./valid_cert.yaml" ]; then
    echo "File './valid_cert.yaml' does not exist!"
    exit 1
fi

if echo "$output" | grep -qi "1 valid certificates" && \
   echo "$output" | grep -qi "0 certificates expiring soon" && \
   echo "$output" | grep -qi "0 invalid certificates found"; then
   echo "Test passed!"
else
    echo "Test failed!"
    exit 1
fi

output=$(bash ./argo_external_ssl_check.sh ./expired_cert.yaml)
if [ ! -f "./expired_cert.yaml" ]; then
    echo "File './expired_cert.yaml' does not exist!"
    exit 1
fi

if echo "$output" | grep -qi "0 valid certificates" && \
   echo "$output" | grep -qi "0 certificates expiring soon" && \
   echo "$output" | grep -qi "1 invalid certificates found"; then
   echo "Test passed!"
else
    echo "Test failed!"
    exit 1
fi

# generate test expiring soon (3 days) certificate
openssl genpkey -algorithm RSA -out private_key.pem
openssl req -new -key private_key.pem -out csr.pem -subj "/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=example.com"
openssl x509 -req -in csr.pem -signkey private_key.pem -out new_cert.pem -days 3
openssl x509 -in new_cert.pem -noout -enddate
cat new_cert.pem > certificate.yaml

output=$(bash ./argo_external_ssl_check.sh ./certificate.yaml)
if [ ! -f "./certificate.yaml" ]; then
    echo "File './certificate.yaml' does not exist!"
    exit 1
fi

if echo "$output" | grep -qi "0 valid certificates" && \
   echo "$output" | grep -qi "1 certificates expiring soon" && \
   echo "$output" | grep -qi "0 invalid certificates found"; then
   echo "Test passed!"
else
    echo "Test failed!"
    exit 1
fi

exit 0
