{ config, lib, pkgs, ... }:

with lib;

let
  cfg  = config.programs.ssh;

  knownHosts = map (h: getAttr h cfg.knownHosts) (attrNames cfg.knownHosts);

  host =
    { name, ... }:
    {
      options = {
        hostNames = mkOption {
          type = types.listOf types.str;
          default = [];
          description = ''
            A list of host names and/or IP numbers used for accessing
            the host's ssh service.
          '';
        };
        publicKey = mkOption {
          default = null;
          type = types.nullOr types.str;
          example = "ecdsa-sha2-nistp521 AAAAE2VjZHN...UEPg==";
          description = ''
            The public key data for the host. You can fetch a public key
            from a running SSH server with the <command>ssh-keyscan</command>
            command. The public key should not include any host names, only
            the key type and the key itself.
          '';
        };
        publicKeyFile = mkOption {
          default = null;
          type = types.nullOr types.path;
          description = ''
            The path to the public key file for the host. The public
            key file is read at build time and saved in the Nix store.
            You can fetch a public key file from a running SSH server
            with the <command>ssh-keyscan</command> command. The content
            of the file should follow the same format as described for
            the <literal>publicKey</literal> option.
          '';
        };
      };
      config = {
        hostNames = mkDefault [ name ];
      };
    };
in

{
  options = {

    programs.ssh.knownHosts = mkOption {
      default = {};
      type = types.attrsOf (types.submodule host);
      description = ''
        The set of system-wide known SSH hosts.
      '';
      example = literalExample ''
        [
          {
            hostNames = [ "myhost" "myhost.mydomain.com" "10.10.1.4" ];
            publicKeyFile = ./pubkeys/myhost_ssh_host_dsa_key.pub;
          }
          {
            hostNames = [ "myhost2" ];
            publicKeyFile = ./pubkeys/myhost2_ssh_host_dsa_key.pub;
          }
        ]
      '';
    };
  };

  config = {

    assertions = flip mapAttrsToList cfg.knownHosts (name: data: {
      assertion = (data.publicKey == null && data.publicKeyFile != null) ||
                  (data.publicKey != null && data.publicKeyFile == null);
      message = "knownHost ${name} must contain either a publicKey or publicKeyFile";
    });

    environment.etc."ssh/ssh_known_hosts".text = (flip (concatMapStringsSep "\n") knownHosts
      (h: assert h.hostNames != [];
        concatStringsSep "," h.hostNames + " "
        + (if h.publicKey != null then h.publicKey else readFile h.publicKeyFile)
      )) + "\n";

  };
}
