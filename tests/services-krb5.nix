{ config, pkgs, ... }: {
  krb5 = {
    enable = true;
    kerberos = pkgs.krb5;
    libdefaults = { default_realm = "ATHENA.MIT.EDU"; };
    realms = {
      "ATHENA.MIT.EDU" = {
        admin_server = "athena.mit.edu";
        kdc = [ "athena01.mit.edu" "athena02.mit.edu" ];
      };
    };
    domain_realm = {
      "example.com" = "EXAMPLE.COM";
      ".example.com" = "EXAMPLE.COM";
    };
    capaths = {
      "ATHENA.MIT.EDU" = { "EXAMPLE.COM" = "."; };
      "EXAMPLE.COM" = { "ATHENA.MIT.EDU" = "."; };
    };
    appdefaults = {
      pam = {
        debug = false;
        ticket_lifetime = 36000;
        renew_lifetime = 36000;
        max_timeout = 30;
        timeout_shift = 2;
        initial_timeout = 1;
      };
    };
    plugins = { ccselect = { disable = "k5identity"; }; };
    extraConfig = ''
      [logging]
        kdc          = SYSLOG:NOTICE
        admin_server = SYSLOG:NOTICE
        default      = SYSLOG:NOTICE
    '';
  };
  test = let
    snapshot = pkgs.writeText "krb5-with-example-config.conf" ''
      [libdefaults]
        default_realm = ATHENA.MIT.EDU

      [realms]
        ATHENA.MIT.EDU = {
          admin_server = athena.mit.edu
          kdc = athena01.mit.edu
          kdc = athena02.mit.edu
        }

      [domain_realm]
        .example.com = EXAMPLE.COM
        example.com = EXAMPLE.COM

      [capaths]
        ATHENA.MIT.EDU = {
          EXAMPLE.COM = .
        }
        EXAMPLE.COM = {
          ATHENA.MIT.EDU = .
        }

      [appdefaults]
        pam = {
          debug = false
          initial_timeout = 1
          max_timeout = 30
          renew_lifetime = 36000
          ticket_lifetime = 36000
          timeout_shift = 2
        }

      [plugins]
        ccselect = {
          disable = k5identity
        }

      [logging]
        kdc          = SYSLOG:NOTICE
        admin_server = SYSLOG:NOTICE
        default      = SYSLOG:NOTICE
    '';
  in ''
    echo "checking correctness of krb5.conf" >&2
    diff ${config.out}/etc/krb5.conf ${snapshot}
  '';
}
