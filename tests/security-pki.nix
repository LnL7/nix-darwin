{ config, pkgs, ... }:

{
  security.pki.certificates = [
    ''
      Fake Root CA
      ------------
    ''
  ];

  test = ''
    echo "checking for ca-certificates.crt in /etc" >&2
    test -e ${config.out}/etc/ssl/certs/ca-certificates.crt

    echo "checking NIX_SSL_CERT_FILE in set-environment" >&2
    grep 'NIX_SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"' ${config.system.build.setEnvironment}

    echo "checking for certificates in ca-certificates.crt" >&2
    grep -q 'BEGIN CERTIFICATE' ${config.out}/etc/ssl/certs/ca-certificates.crt

    echo "checking for extra certificate in ca-certificates.crt" >&2
    grep 'Fake Root CA' ${config.out}/etc/ssl/certs/ca-certificates.crt
  '';
}
