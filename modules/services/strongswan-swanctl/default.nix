{ config, lib, pkgs, ... }:

with lib;
with (import ./param-lib.nix lib);

let
  cfg = config.services.strongswan-swanctl;
  swanctlParams = import ./swanctl-params.nix lib;
in  {
  options.services.strongswan-swanctl = {
    enable = mkEnableOption (lib.mdDoc "strongswan-swanctl service");

    package = mkOption {
      type = types.package;
      default = pkgs.strongswan;
      defaultText = literalExpression "pkgs.strongswan";
      description = lib.mdDoc ''
        The strongswan derivation to use.
      '';
    };


    strongswan.extraConfig = mkOption {
      type = types.str;
      default = "";
      description = lib.mdDoc ''
        Contents of the `strongswan.conf` file.
      '';
    };

    swanctl = paramsToOptions swanctlParams;
  };

  config = mkIf cfg.enable {

    assertions = [
      { assertion = !config.services.strongswan.enable;
        message = "cannot enable both services.strongswan and services.strongswan-swanctl. Choose either one.";
      }
    ];

    environment.etc."swanctl/swanctl.conf".text = paramsToConf cfg.swanctl swanctlParams;

    # The swanctl command complains when the following directories don't exist:
    # See: https://wiki.strongswan.org/projects/strongswan/wiki/Swanctldirectory
    system.activationScripts.strongswan-swanctl-etc.text =
    ''
      mkdir -p '/etc/swanctl/x509'     # Trusted X.509 end entity certificates
      mkdir -p '/etc/swanctl/x509ca'   # Trusted X.509 Certificate Authority certificates
      mkdir -p '/etc/swanctl/x509ocsp'
      mkdir -p '/etc/swanctl/x509aa'   # Trusted X.509 Attribute Authority certificates
      mkdir -p '/etc/swanctl/x509ac'   # Attribute Certificates
      mkdir -p '/etc/swanctl/x509crl'  # Certificate Revocation Lists
      mkdir -p '/etc/swanctl/pubkey'   # Raw public keys
      mkdir -p '/etc/swanctl/private'  # Private keys in any format
      mkdir -p '/etc/swanctl/rsa'      # PKCS#1 encoded RSA private keys
      mkdir -p '/etc/swanctl/ecdsa'    # Plain ECDSA private keys
      mkdir -p '/etc/swanctl/bliss'
      mkdir -p '/etc/swanctl/pkcs8'    # PKCS#8 encoded private keys of any type
      mkdir -p '/etc/swanctl/pkcs12'   # PKCS#12 containers

      rm -rf ${pkgs.strongswan}/etc/swanctl/swanctl.conf
      rm -rf ${pkgs.strongswan}/etc/swanctl/x509
      rm -rf ${pkgs.strongswan}/etc/swanctl/x509ca
      rm -rf ${pkgs.strongswan}/etc/swanctl/x509ocsp
      rm -rf ${pkgs.strongswan}/etc/swanctl/x509aa
      rm -rf ${pkgs.strongswan}/etc/swanctl/x509ac
      rm -rf ${pkgs.strongswan}/etc/swanctl/x509crl
      rm -rf ${pkgs.strongswan}/etc/swanctl/pubkey
      rm -rf ${pkgs.strongswan}/etc/swanctl/private
      rm -rf ${pkgs.strongswan}/etc/swanctl/rsa
      rm -rf ${pkgs.strongswan}/etc/swanctl/ecdsa
      rm -rf ${pkgs.strongswan}/etc/swanctl/bliss
      rm -rf ${pkgs.strongswan}/etc/swanctl/pkcs8
      rm -rf ${pkgs.strongswan}/etc/swanctl/pkcs12
      ln -s /etc/swanctl/swanctl.conf ${pkgs.strongswan}/etc/swanctl/swanctl.conf
      ln -s /etc/swanctl/x509 ${pkgs.strongswan}/etc/swanctl/x509
      ln -s /etc/swanctl/x509ca ${pkgs.strongswan}/etc/swanctl/x509ca
      ln -s /etc/swanctl/x509ocsp ${pkgs.strongswan}/etc/swanctl/x509ocsp
      ln -s /etc/swanctl/x509aa ${pkgs.strongswan}/etc/swanctl/x509aa
      ln -s /etc/swanctl/x509ac ${pkgs.strongswan}/etc/swanctl/x509ac
      ln -s /etc/swanctl/x509crl ${pkgs.strongswan}/etc/swanctl/x509crl
      ln -s /etc/swanctl/pubkey ${pkgs.strongswan}/etc/swanctl/pubkey
      ln -s /etc/swanctl/private ${pkgs.strongswan}/etc/swanctl/private
      ln -s /etc/swanctl/rsa ${pkgs.strongswan}/etc/swanctl/rsa
      ln -s /etc/swanctl/ecdsa ${pkgs.strongswan}/etc/swanctl/ecdsa
      ln -s /etc/swanctl/bliss ${pkgs.strongswan}/etc/swanctl/bliss
      ln -s /etc/swanctl/pkcs8 ${pkgs.strongswan}/etc/swanctl/pkcs8
      ln -s /etc/swanctl/pkcs12 ${pkgs.strongswan}/etc/swanctl/pkcs12
     '';

    launchd.daemons.strongswan-swanctl = {
      script = "
        ${pkgs.strongswan}/sbin/ipsec start --nofork && ${cfg.package}/sbin/swanctl --load-all --noprompt
      ";
      environment = {
        SWANCTL_DIR = "/etc/swanctl";
      };
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive.NetworkState = true;
        StandardErrorPath = "${config.launchd.daemons.strongswan-swanctl.environment.SWANCTL_DIR}/buildkite-agent.log";
        StandardOutPath = "${config.launchd.daemons.strongswan-swanctl.environment.SWANCTL_DIR}/buildkite-agent.log";
      };
    };
  };
}
