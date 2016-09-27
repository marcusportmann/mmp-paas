#!/bin/bash

#[ $# -ne 3 ] && { echo "Usage: $0 \"Organisation Name\" \"Business Unit Name\" \"Business Unit or Application Name\""; exit 1; }
#ORGANISATION_NAME=$1
#BUSINESS_UNIT_NAME=$2
#APPLICATION_NAME=$3

ORGANISATION_NAME=MMP
BUSINESS_UNIT_NAME=Development
APPLICATION_NAME=""

# Delete any existing directories
rm -rf root-ca
rm -rf paas-ca
rm -rf paas


# Create the required directory structure
mkdir -p root-ca/newcerts
mkdir -p paas-ca/newcerts
mkdir -p paas


# Initialise the root CA   
touch root-ca/index.txt

echo 01 > root-ca/serial

root_ca_password=$(openssl rand -base64 20)
root_ca_password=${root_ca_password:0:16}
echo $root_ca_password > root-ca/root-ca-password
   
cat <<EOF > root-ca/root-ca.config
[ ca ]
default_ca               = root_ca
[ root_ca ]
dir                      = .
certs                    = .
new_certs_dir            = root-ca/newcerts
database                 = root-ca/index.txt
serial                   = root-ca/serial
certificate              = root-ca/root-ca.crt
private_key              = root-ca/root-ca.key
default_days             = 7300
default_crl_days         = 30
default_md               = sha256
preserve                 = yes
x509_extensions          = v3_ca
policy                   = policy_root_ca
[ policy_root_ca ]
organizationName         = match
organizationalUnitName   = match
commonName               = match
commonName               = supplied
[ v3_ca ]
# Extensions for a typical CA
subjectKeyIdentifier     = hash
authorityKeyIdentifier   = keyid:always,issuer
basicConstraints         = critical, CA:true
keyUsage                 = critical, digitalSignature, cRLSign, keyCertSign
[ v3_intermediate_ca ]
# Extensions for a typical intermediate
subjectKeyIdentifier     = hash
authorityKeyIdentifier   = keyid:always,issuer
basicConstraints         = critical, CA:true, pathlen:0
keyUsage                 = critical, digitalSignature, cRLSign, keyCertSign
EOF

openssl genrsa -out root-ca/root-ca.key 4096
openssl req -new -extensions v3_ca -x509 -days 7300 -key root-ca/root-ca.key -out root-ca/root-ca.crt -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority"
openssl x509 -text -in root-ca/root-ca.crt
openssl pkcs12 -export -name "${APPLICATION_NAME} Root Certificate Authority" -out root-ca/root-ca.p12 -inkey root-ca/root-ca.key -in root-ca/root-ca.crt -passout pass:$root_ca_password
openssl pkcs12 -export -name "${APPLICATION_NAME} Root Certificate Authority" -nokeys -out root-ca/root-ca-public.p12 -in root-ca/root-ca.crt -passout pass:RootCA


# Initialise the PaaS CA   
touch paas-ca/index.txt

echo 01 > paas-ca/serial

paas_ca_password=$(openssl rand -base64 20)
paas_ca_password=${paas_ca_password:0:16}
echo $paas_ca_password > paas-ca/paas-ca-password
   
cat <<EOF > paas-ca/paas-ca.config
[ ca ]
default_ca               = paas_ca
[ paas_ca ]
dir                      = .
certs                    = .
new_certs_dir            = paas-ca/newcerts
database                 = paas-ca/index.txt
serial                   = paas-ca/serial
certificate              = paas-ca/paas-ca.crt
private_key              = paas-ca/paas-ca.key
default_days             = 7300
default_crl_days         = 30
default_md               = sha256
preserve                 = yes
x509_extensions          = server_and_client_cert
policy                   = policy_paas_ca
[ policy_paas_ca ]
organizationName         = match
organizationalUnitName   = match
commonName               = match
commonName               = match
commonName               = supplied
[ server_and_client_cert ]
subjectKeyIdentifier     = hash
basicConstraints         = critical, CA:FALSE
#nsCertType              = server
#nsComment               = "${APPLICATION_NAME}PaaS Certificate Authority Client and Server Certificate"
authorityKeyIdentifier   = keyid,issuer:always
keyUsage                 = critical, digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement
extendedKeyUsage         = serverAuth,clientAuth
[ server_cert ]
subjectKeyIdentifier     = hash
basicConstraints         = critical, CA:FALSE
nsCertType               = server
nsComment                = "${APPLICATION_NAME}PaaS Certificate Authority Server Certificate"
authorityKeyIdentifier   = keyid,issuer:always
keyUsage                 = critical, digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement
extendedKeyUsage         = serverAuth
[ client_cert ]
subjectKeyIdentifier     = hash
basicConstraints         = critical, CA:FALSE
nsCertType               = client
nsComment                = "${APPLICATION_NAME}PaaS Certificate Authority Client Certificate"
authorityKeyIdentifier   = keyid,issuer:always
keyUsage                 = critical, digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement
extendedKeyUsage         = clientAuth
EOF

openssl genrsa -out paas-ca/paas-ca.key 4096
openssl req -new -nodes -key paas-ca/paas-ca.key -out paas-ca/paas-ca.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority"
openssl ca -extensions v3_intermediate_ca  -batch -config root-ca/root-ca.config -in paas-ca/paas-ca.csr -out paas-ca/paas-ca.crt -keyfile root-ca/root-ca.key
openssl x509 -text -in paas-ca/paas-ca.crt

# Create the paas-client certificate
openssl genrsa -out paas/paas-client.key 4096
openssl req -new -nodes -key paas/paas-client.key -out paas/paas-client.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority/CN=client"
openssl ca -extensions client_cert -batch -config paas-ca/paas-ca.config -in paas/paas-client.csr -out paas/paas-client.crt -keyfile paas-ca/paas-ca.key
openssl x509 -text -in paas/paas-client.crt

# Create the paas-registry certificate
openssl genrsa -out paas/paas-registry.key 4096
openssl req -new -nodes -key paas/paas-registry.key -out paas/paas-registry.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority/CN=paas-registry"
openssl ca -extensions server_and_client_cert -batch -config paas-ca/paas-ca.config -in paas/paas-registry.csr -out paas/paas-registry.crt -keyfile paas-ca/paas-ca.key
openssl x509 -text -in paas/paas-registry.crt

# Create the paas-host-1 certificate
openssl genrsa -out paas/paas-host-1.key 4096
openssl req -new -nodes -key paas/paas-host-1.key -out paas/paas-host-1.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority/CN=paas-host-1.local"
openssl ca -extensions server_and_client_cert -batch -config paas-ca/paas-ca.config -in paas/paas-host-1.csr -out paas/paas-host-1.crt -keyfile paas-ca/paas-ca.key
openssl x509 -text -in paas/paas-host-1.crt

# Create the paas-host-2 certificate
openssl genrsa -out paas/paas-host-2.key 4096
openssl req -new -nodes -key paas/paas-host-2.key -out paas/paas-host-2.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority/CN=paas-host-2.local"
openssl ca -extensions server_and_client_cert -batch -config paas-ca/paas-ca.config -in paas/paas-host-2.csr -out paas/paas-host-2.crt -keyfile paas-ca/paas-ca.key
openssl x509 -text -in paas/paas-host-2.crt

# Create the paas-host-3 certificate
openssl genrsa -out paas/paas-host-3.key 4096
openssl req -new -nodes -key paas/paas-host-3.key -out paas/paas-host-3.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority/CN=paas-host-3.local"
openssl ca -extensions server_and_client_cert -batch -config paas-ca/paas-ca.config -in paas/paas-host-3.csr -out paas/paas-host-3.crt -keyfile paas-ca/paas-ca.key
openssl x509 -text -in paas/paas-host-3.crt

# Create the paas-host-4 certificate
openssl genrsa -out paas/paas-host-4.key 4096
openssl req -new -nodes -key paas/paas-host-4.key -out paas/paas-host-4.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority/CN=paas-host-4.local"
openssl ca -extensions server_and_client_cert -batch -config paas-ca/paas-ca.config -in paas/paas-host-4.csr -out paas/paas-host-4.crt -keyfile paas-ca/paas-ca.key
openssl x509 -text -in paas/paas-host-4.crt

# Create the paas-host-5 certificate
openssl genrsa -out paas/paas-host-5.key 4096
openssl req -new -nodes -key paas/paas-host-5.key -out paas/paas-host-5.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority/CN=paas-host-5.local"
openssl ca -extensions server_and_client_cert -batch -config paas-ca/paas-ca.config -in paas/paas-host-5.csr -out paas/paas-host-5.crt -keyfile paas-ca/paas-ca.key
openssl x509 -text -in paas/paas-host-5.crt

# Create the paas-host-6 certificate
openssl genrsa -out paas/paas-host-6.key 4096
openssl req -new -nodes -key paas/paas-host-6.key -out paas/paas-host-6.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority/CN=paas-host-6.local"
openssl ca -extensions server_and_client_cert -batch -config paas-ca/paas-ca.config -in paas/paas-host-6.csr -out paas/paas-host-6.crt -keyfile paas-ca/paas-ca.key
openssl x509 -text -in paas/paas-host-6.crt

# Create the developer certificate
openssl genrsa -out paas/developer.key 4096
openssl req -new -nodes -key paas/developer.key -out paas/developer.csr -subj "/O=${ORGANISATION_NAME}/OU=${BUSINESS_UNIT_NAME}/CN=${APPLICATION_NAME}Root Certificate Authority/CN=${APPLICATION_NAME}PaaS Certificate Authority/CN=developer.local"
openssl ca -extensions server_and_client_cert -batch -config paas-ca/paas-ca.config -in paas/developer.csr -out paas/developer.crt -keyfile paas-ca/paas-ca.key
openssl x509 -text -in paas/developer.crt











