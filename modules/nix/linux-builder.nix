{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs) stdenv;

  cfg = config.nix.linux-builder;

  builderWithOverrides = cfg.package.override {
    modules = [ cfg.config ];
  };

  # create-builder uses TMPDIR to share files with the builder, notably certs.
  # macOS will clean up files in /tmp automatically that haven't been accessed in 3+ days.
  # If we let it use /tmp, leaving the computer asleep for 3 days makes the certs vanish.
  # So we'll use /run/org.nixos.linux-builder instead and clean it up ourselves.
  script = pkgs.writeShellScript "linux-builder-start" ''
    export TMPDIR=/run/org.nixos.linux-builder USE_TMPDIR=1
    rm -rf $TMPDIR
    mkdir -p $TMPDIR
    trap "rm -rf $TMPDIR" EXIT
    ${lib.optionalString cfg.ephemeral ''
      rm -f ${cfg.workingDirectory}/${builderWithOverrides.nixosConfig.networking.hostName}.qcow2
    ''}
    ${builderWithOverrides}/bin/create-builder
  '';
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

    supportedFeatures = mkOption {
      type = types.listOf types.str;
      default = [ "kvm" "benchmark" "big-parallel" ];
      description = lib.mdDoc ''
        This option specifies the list of features supported by the Linux builder.

        This sets the corresponding `nix.buildMachines.*.supportedFeatures` option.
      '';
    };

    workingDirectory = mkOption {
      type = types.str;
      default = "/var/lib/darwin-builder";
      description = lib.mdDoc ''
        The working directory of the Linux builder daemon process.
      '';
    };

    ephemeral = mkEnableOption (lib.mdDoc ''
      wipe the builder's filesystem on every restart.

      This is disabled by default as maintaining the builder's Nix Store reduces
      rebuilds. You can enable this if you don't want your builder to accumulate
      state.
    '');
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
      mkdir -p ${cfg.workingDirectory}
    '';

    launchd.daemons.linux-builder = {
      environment = {
        inherit (config.environment.variables) NIX_SSL_CERT_FILE;
      };
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh" "-c"
          "/bin/wait4path /nix/store &amp;&amp; exec ${script}"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        WorkingDirectory = cfg.workingDirectory;
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
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpCV2N4Yi9CbGFxdDFhdU90RStGOFFVV3JVb3RpQzVxQkorVXVFV2RWQ2Igcm9vdEBuaXhvcwo=";
      inherit (cfg) maxJobs supportedFeatures;
    }];

    nix.settings.builders-use-substitutes = true;
  };
}
