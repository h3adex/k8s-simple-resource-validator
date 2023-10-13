#!/bin/bash

if [ -n "$DEBUG" ]; then
	set -x
fi

openssl genrsa -out bin/ca.key 2048

openssl req -new -x509 -days 365 -key bin/ca.key \
  -subj "/C=AU/CN=k8s-simple-resource-validator"\
  -out bin/ca.crt

openssl req -newkey rsa:2048 -nodes -keyout bin/tls.key \
  -subj "/C=AU/CN=k8s-simple-resource-validator" \
  -out bin/server.csr

openssl x509 -req \
  -extfile <(printf "subjectAltName=DNS:k8s-simple-resource-validator.default.svc") \
  -days 365 \
  -in bin/server.csr \
  -CA bin/ca.crt -CAkey bin/ca.key -CAcreateserial \
  -out bin/tls.crt