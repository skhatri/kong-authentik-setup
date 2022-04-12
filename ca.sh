#create CA cert and self sign

: "${keysize:=${2:-2048}}"

cert_base="certs"
ca="${cert_base}/ca"
if [[ ! -d ${ca} ]];
then
  mkdir -p ${ca}
  openssl genrsa -out ${ca}/ca.key ${keysize}
  openssl req -new -x509 -key ${ca}/ca.key -out ${ca}/ca.crt -subj "/C=AU/ST=NSW/L=Sydney/O=Software Company/OU=IT/CN=local-ca"
fi;


cert_name=${1:-localhost}
if [[ "${cert_name}" == "ca" ]] || [[ "${cert_name}" == "keys" ]];
then
  echo "invalid server name. ca and keys are reserved names"
  exit 1;
fi;

cert_dir="${cert_base}/output/${cert_name}"
if [[ ! -d ${cert_dir} ]];
then
  mkdir -p ${cert_dir}
fi;

### Server Setup
KEY_FILE="${cert_dir}/server.p12"
STORE_PASS="test123"
keytool -genkeypair -keyalg RSA -keysize ${keysize} -storetype PKCS12 -keystore ${KEY_FILE} -validity 365 --dname "CN=${cert_name}, OU=IT, O=Software Company, L=World, ST=World, C=WO" -storepass ${STORE_PASS}

keytool -certreq -keystore ${KEY_FILE} -file ${cert_dir}/server.csr -storepass ${STORE_PASS}



#CA sign cert request
openssl x509 -req -in ${cert_dir}/server.csr -days 365 -CA $ca/ca.crt -CAkey $ca/ca.key -CAcreateserial -out ${cert_dir}/server.crt

openssl x509 -in ${cert_dir}/server.crt -noout -text
cat ${cert_dir}/server.crt ${ca}/ca.crt > ${cert_dir}/bundle.crt
openssl x509 -in ${cert_dir}/bundle.crt -noout -text

### Server Import Cert
keytool -importcert -file ${cert_dir}/bundle.crt -keystore ${KEY_FILE} -storepass ${STORE_PASS} -trustcacerts

echo extracting private key
openssl pkcs12 -info -in ${cert_dir}/server.p12 -nodes -nocerts -out ${cert_dir}/server.key
openssl rsa -in ${cert_dir}/server.key -out ${cert_dir}/server.rsa.key


keys="${cert_base}/keys/${cert_name}"
if [[ ! -d ${keys} ]];
then
  mkdir -p ${keys}
fi;
cp ${cert_dir}/server.rsa.key ${keys}/server.pem
cp ${cert_dir}/server.crt ${keys}/server.crt
