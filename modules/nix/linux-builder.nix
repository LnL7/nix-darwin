{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs) stdenv;

  cfg = config.nix.linux-builder;

  builderWithOverrides = cfg.package.override {
    modules = [ cfg.config ];
  };
in

{
  imports = [
    (mkRemovedOptionModule [ "nix" "linux-builder" "modules" ] "This option has been replaced with `nix.linux-builder.config` which allows setting options directly like `nix.linux-builder.config.networking.hostName = \"banana\";.")
  ];

  options.nix.linux-builder = {
    enable = mkEnableOption (lib.mdDoc "Linux builder");

    package = mkOption {
      type = types.package;
      default = pkgs.darwin.linux-builder;
      defaultText = "pkgs.darwin.linux-builder";
      description = lib.mdDoc ''
        This option specifies the Linux builder to use.
      '';
    };

    config = mkOption {
      type = types.deferredModule;
      default = { };
      example = literalExpression ''
        ({ pkgs, ... }:

        {
          environment.systemPackages = [ pkgs.neovim ];
        })
      '';
      description = lib.mdDoc ''
        This option specifies extra NixOS configuration for the builder. You should first use the Linux builder
        without changing the builder configuration otherwise you may not be able to build the Linux builder.
      '';
    };

    maxJobs = mkOption {
      type = types.ints.positive;
      default = 1;
      example = 4;
      description = lib.mdDoc ''
        This option specifies the maximum number of jobs to run on the Linux builder at once.

        This sets the corresponding `nix.buildMachines.*.maxJobs` option.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [ {
      assertion = config.nix.settings.trusted-users != [ "root" ] || (config.nix.settings.extra-trusted-users or [ ]) != [ ];
      message = ''
        Your user or group (@admin) needs to be added to `nix.settings.trusted-users` or `nix.settings.extra-trusted-users`
        to use the Linux builder.
      '';
    } ];

    system.activationScripts.preActivation.text = ''
      mkdir -p /var/lib/darwin-builder
    '';

    launchd.daemons.linux-builder = {
      environment = {
        inherit (config.environment.variables) NIX_SSL_CERT_FILE;
      };
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh" "-c"
          "/bin/wait4path /nix/store &amp;&amp; exec ${builderWithOverrides}/bin/create-builder"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        WorkingDirectory = "/var/lib/darwin-builder";
      };
    };

    environment.etc."ssh/ssh_config.d/100-linux-builder.conf".text = ''
      Host linux-builder
        Hostname localhost
        HostKeyAlias linux-builder
        Port 31022
    '';

    nix.distributedBuilds = true;

    nix.buildMachines = [{
      hostName = "linux-builder";
      sshUser = "builder";
      sshKey = "/etc/nix/builder_ed25519";
      system = "${stdenv.hostPlatform.uname.processor}-linux";
      supportedFeatures = [ "kvm" "benchmark" "big-parallel" ];
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpCV2N4Yi9CbGFxdDFhdU90RStGOFFVV3JVb3RpQzVxQkorVXVFV2RWQ2Igcm9vdEBuaXhvcwo=";
      inherit (cfg) maxJobs;
    }];

    nix.settings.builders-use-substitutes = true;
  };
}
