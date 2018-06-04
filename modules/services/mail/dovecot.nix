{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dovecot;

  baseDir = "/run/dovecot2";
  stateDir = "/var/lib/dovecot";

  configFile = pkgs.writeText "dovecot.conf" concatStrings[
    ''
      base_dir = ${baseDir}
      protocols = ${concatStringsSep " " cfg.protocols}
      sendmail_path = /run/wrappers/bin/sendmail
    ''

    (if isNull cfg.sslServerCert then ''
      ssl = no
      disable_plaintext_auth = no
    '' else ''
      ssl_cert = <${cfg.sslServerCert}
      ssl_key = <${cfg.sslServerKey}
      ${optionalString (!(isNull cfg.sslCACert)) ("ssl_ca = <" + cfg.sslCACert)}
      ssl_dh = <${config.security.dhparams.params.dovecot2.path}
      disable_plaintext_auth = yes
    '')

    ''
      default_internal_user = ${cfg.user}
      default_internal_group = ${cfg.group}
      ${optionalString (cfg.mailUser != null) "mail_uid = ${cfg.mailUser}"}
      ${optionalString (cfg.mailGroup != null) "mail_gid = ${cfg.mailGroup}"}

      mail_location = ${cfg.mailLocation}

      maildir_copy_with_hardlinks = yes
      pop3_uidl_format = %08Xv%08Xu

      auth_mechanisms = plain login

      service auth {
        user = root
      }
    ''

    (optionalString (cfg.sieveScripts != {}) ''
      plugin {
        ${concatStringsSep "\n" (mapAttrsToList (to: from: "sieve_${to} = ${stateDir}/sieve/${to}") cfg.sieveScripts)}
      }
    '')

    (optionalString (cfg.mailboxes != []) ''
      protocol imap {
        namespace inbox {
          inbox=yes
          ${concatStringsSep "\n" (map mailboxConfig cfg.mailboxes)}
        }
      }
    '')

    (optionalString cfg.enableQuota ''
      mail_plugins = $mail_plugins quota
      service quota-status {
        executable = ${dovecotPkg}/libexec/dovecot/quota-status -p postfix
        inet_listener {
          port = ${cfg.quotaPort}
        }
        client_limit = 1
      }

      protocol imap {
        mail_plugins = $mail_plugins imap_quota
      }

      plugin {
        quota_rule = *:storage=${cfg.quotaGlobalPerUser}
        quota = maildir:User quota # per virtual mail user quota # BUG/FIXME broken, we couldn't get this working
        quota_status_success = DUNNO
        quota_status_nouser = DUNNO
        quota_status_overquota = "552 5.2.2 Mailbox is full"
        quota_grace = 10%%
      }
    '')

    cfg.extraConfig
  ];

  modulesDir = pkgs.symlinkJoin {
    name = "dovecot-modules";
    paths = map (pkg: "${pkg}/lib/dovecot") ([ dovecotPkg ] ++ map (module: module.override { dovecot = dovecot; }) cfg.modules);
  };

  mailboxConfig = mailbox: ''
    mailbox "${mailbox.name}" {
      auto = ${toString mailbox.auto}
  '' + optionalString (mailbox.specialUse != null) ''
      special_use = \${toString mailbox.specialUse}
  '' + "}";

  mailboxes = { lib, pkgs, ... }: {
    options = {
      name = mkOption {
        type = types.strMatching ''[^"]+'';
        example = "Spam";
        description = "The name of the mailbox.";
      };
      auto = mkOption {
        type = types.enum [ "no" "create" "subscribe" ];
        default = "no";
        example = "subscribe";
        description = "Whether to automatically create or create and subscribe to the mailbox or not.";
      };
      specialUse = mkOption {
        type = types.nullOr (types.enum [ "All" "Archive" "Drafts" "Flagged" "Junk" "Sent" "Trash" ]);
        default = null;
        example = "Junk";
        description = "Null if no special use flag is set. Other than that every use flag mentioned in the RFC is valid.";
      };
    };
  };
in {

  options.services.dovecot = {
    enable = mkEnableOption "Dovecot 2.x POP3/IMAP server";

    security.dhparams = mkIf (! isNull cfg.sslServerCert) {
      enable = true;
      params.dovecot2 = {};
    };

    package = mkOption {
      type = types.package;
      default = pkgs.dovecot;
      defaultText = "pkgs.dovecot";
      description = "Dovecot derivation to use.";
    };

    path = mkOption {
      type = types.listOf types.path;
      default = [];
      example = literalExample "[ pkgs.pass pkgs.bash pkgs.notmuch ]";
      description = "List of derivations to put in Offlineimap's path.";
    };

    enablePop3 = mkOption {
      type = types.bool;
      default = false;
      description = "Start the POP3 listener (when Dovecot is enabled).";
    };

    enableImap = mkOption {
      type = types.bool;
      default = true;
      description = "Start the IMAP listener (when Dovecot is enabled).";
    };

    enableLmtp = mkOption {
      type = types.bool;
      default = false;
      description = "Start the LMTP listener (when Dovecot is enabled).";
    };

    protocols = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional listeners to start when Dovecot is enabled.";
    };

    user = mkOption {
      type = types.str;
      default = "dovecot2";
      description = "Dovecot user name.";
    };

    group = mkOption {
      type = types.str;
      default = "dovecot2";
      description = "Dovecot group name.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = "mail_debug = yes";
      description = "Additional entries to put verbatim into Dovecot's config file.";
    };

    configFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Config file used for the whole dovecot configuration.";
      apply = v: if v != null then v else pkgs.writeText "dovecot.conf" dovecotConf;
    };

    mailLocation = mkOption {
      type = types.str;
      default = "maildir:/var/spool/mail/%u"; /* Same as inbox, as postfix */
      example = "maildir:~/mail:INBOX=/var/spool/mail/%u";
      description = ''
        Location that dovecot will use for mail folders. Dovecot mail_location option.
      '';
    };

    mailUser = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default user to store mail for virtual users.";
    };

    mailGroup = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default group to store mail for virtual users.";
    };

    modules = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExample "[ pkgs.dovecot_pigeonhole ]";
      description = ''
        Symlinks the contents of lib/dovecot of every given package into
        /etc/dovecot/modules. This will make the given modules available
        if a dovecot package with the module_dir patch applied is being used.
      '';
    };

    sslCACert = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to the server's CA certificate key.";
    };

    sslServerCert = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to the server's public key.";
    };

    sslServerKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to the server's private key.";
    };

    sieveScripts = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Sieve scripts to be executed. Key is a sequence, e.g. 'before2', 'after' etc.";
    };

    mailboxes = mkOption {
      type = types.listOf (types.submodule mailboxes);
      default = [];
      example = [ { name = "Spam"; specialUse = "Junk"; auto = "create"; } ];
      description = "Configure mailboxes and auto create or subscribe them.";
    };

    enableQuota = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Whether to enable the dovecot quota service.";
    };

    quotaPort = mkOption {
      type = types.str;
      default = "12340";
      description = ''
        The Port the dovecot quota service binds to.
        If using postfix, add check_policy_service inet:localhost:12340 to your smtpd_recipient_restrictions in your postfix config.
      '';
    };
    quotaGlobalPerUser = mkOption {
      type = types.str;
      default = "100G";
      example = "10G";
      description = "Quota limit for the user in bytes. Supports suffixes b, k, M, G, T and %.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    environment.etc."dovecot/modules".source = modulesDir;
    environment.etc."dovecot/dovecot.conf".source = cfg.configFile;
    launchd.daemons.dovecot = {
      path                            = [ cfg.package ] ++ cfg.path;
      command                         = "dovecot";
      serviceConfig.ProgramArguments  = [ "-F" "-c" "/etc/dovecot/dovecot.conf" ];
      serviceConfig.KeepAlive         = false;
      serviceConfig.RunAtLoad         = true;
      serviceConfig.StandardErrorPath = "/var/log/dovecot.log";
      serviceConfig.StandardOutPath   = "/var/log/dovecot.log";
    };
  };
}
