#!/bin/sh

set -e

usage() {
  cat <<EOT

alpine-stunnel is a light utility container for creating secure tunnels. It builds on stunnel; learn more about stunnel on its home page: https://www.stunnel.org/index.html.

ENVIRONMENT VARIABLE OPTIONS:

  CA_CERT   Required; specifies the path to the root certificate (CA)

  CERT      Required; specifies the path to the client certificate
  
  KEY       Required; specifies the path to the private key

  ACCEPT    Optional; specifies the listen address. Defaults to 0.0.0.0:4442

  CONNECT   Required; specifies the endpoint to connect to, in the form <host>:<port>.

  CLIENT    Optional; specifies that the connect endpoint is a daemon that this secure
            tunnel will protect. This corresponds to stunnel's "client = no" setting.

            Adding this flag indicates that this end of the tunnel is where TLS
            termination occurs and that the backend (connect port) is insecure.

            Leaving this flag off indicates that clients will connect to this end of
            the tunnel without TLS, and that this end of the tunnel establishes TLS
            on behalf of the accepted clients.


EXAMPLES:

  1. Assume a legacy HTTP server on 10.0.0.10, place a secure tunnel in front
     of the insecure server, effectively establishing SSL/TLS:

  > docker run -d -p 443:4442 \
      -v /my/local/file-system/ca.crt:/etc/pki/ca.crt \
      -v /my/local/file-system/client.crt:/etc/pki/client.crt \
      -v /my/local/file-system/client.key:/etc/pki/client.key \
      -e ACCEPT="0.0.0.0:4442"
      -e CACERT="/etc/pki/ca.crt" \
      -e CERT="/etc/pki/client.crt" \
      -e KEY="/etc/pki/ca.key" \
      -e CONNECT="10.0.0.10:80" \
      -e CLIENT="no" \
      aloha2you/stunnel
EOT
}


[[ -z ${CONNECT} ]] &&\
  printf '\nMissing environment variable: CONNECT\n' 1>&2 &&\
  usage && exit 1

[[ -z ${CA_CERT} ]] &&\
  printf '\nMissing environment variable: CA_CERT\n' 1>&2 &&\
  usage && exit 1

[[ -z ${CERT} ]] &&\
  printf '\nMissing environment variable: CERT\n' 1>&2 &&\
  usage && exit 1

[[ -z ${KEY} ]] &&\
  printf '\nMissing environment variable: KEY\n' 1>&2 &&\
  usage && exit 1

ACCEPT=${ACCEPT:-0.0.0.0:4442}
CLIENT=${CLIENT:-yes}

mkdir -p /etc/stunnel.d

# Generate a simple stunnel configuration.
cat << EOF > /etc/stunnel.d/stunnel.conf
cert = ${CERT}
key = ${KEY}
cafile = ${CA_CERT}
verify = 2
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
syslog = no
delay = yes
foreground=yes

[backend]
client = ${CLIENT}
accept = ${ACCEPT}
connect = ${CONNECT}
EOF

printf 'Stunneling: %s --> %s\n' ${ACCEPT} ${CONNECT}

exec /usr/bin/stunnel /etc/stunnel.d/stunnel.conf
