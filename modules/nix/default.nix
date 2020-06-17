{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix;

  isNix20 = versionAtLeast (cfg.version or "<unknown>") "1.12pre";

  nixConf =
    let
      # If we're using sandbox for builds, then provide /bin/sh in
      # the sandbox as a bind-mount to bash. This means we also need to
      # include the entire closure of bash.
      sh = pkgs.stdenv.shell;
      binshDeps = pkgs.writeReferencesToFile sh;
    in
      pkgs.runCommandNoCC "nix.conf"
        { preferLocalBuild = true; extraOptions = cfg.extraOptions; }
        ''
          cat > $out <<END
          # WARNING: this file is generated from the nix.* options in
          # your NixOS configuration, typically
          # /etc/nixos/configuration.nix.  Do not edit it!
          ${optionalString cfg.useDaemon ''
            build-users-group = nixbld
          ''}
          ${if isNix20 then "max-jobs" else "build-max-jobs"} = ${toString (cfg.maxJobs)}
          ${if isNix20 then "cores" else "build-cores"} = ${toString (cfg.buildCores)}
          ${if isNix20 then "sandbox" else "build-use-sandbox"} = ${if (builtins.isBool cfg.useSandbox) then boolToString cfg.useSandbox else cfg.useSandbox}
          ${optionalString (cfg.sandboxPaths != []) ''
            ${if isNix20 then "extra-sandbox-paths" else "build-sandbox-paths"} = ${toString cfg.sandboxPaths}
          ''}
          ${if isNix20 then "substituters" else "binary-caches"} = ${toString cfg.binaryCaches}
          ${if isNix20 then "trusted-substituters" else "trusted-binary-caches"} = ${toString cfg.trustedBinaryCaches}
          ${if isNix20 then "trusted-public-keys" else "binary-cache-public-keys"} = ${toString cfg.binaryCachePublicKeys}
          ${if isNix20 then ''
            require-sigs = ${if cfg.requireSignedBinaryCaches then "true" else "false"}
          '' else ''
            signed-binary-caches = ${if cfg.requireSignedBinaryCaches then "*" else ""}
          ''}
          trusted-users = ${toString cfg.trustedUsers}
          allowed-users = ${toString cfg.allowedUsers}
          ${optionalString (isNix20 && !cfg.distributedBuilds) ''
            builders =
          ''}
          $extraOptions
          END
        '';
in

{
  options = {
    nix.package = mkOption {
      type = types.either types.package types.path;
      default = pkgs.nix;
      defaultText = "pkgs.nix";
      example = literalExample "pkgs.nixUnstable";
      description = ''
        This option specifies the package or profile that contains the version of Nix to use throughout the system.
        To keep the version of nix originally installed the default profile can be used.

        eg. /nix/var/nix/profiles/default
      '';
    };

    nix.version = mkOption {
      type = types.str;
      default = "<unknown>";
      example = "1.11.6";
      description = "The version of nix. Used to determine what settings to configure in nix.conf";
    };

    nix.useDaemon = mkOption {
      type = types.bool;
      default = false;
      description = "
        If set, Nix will use the daemon to perform operations.
        Use this instead of services.nix-daemon.enable if you don't wan't the
        daemon service to be managed for you.
      ";
    };

    nix.maxJobs = mkOption {
      type = types.either types.int (types.enum ["auto"]);
      default = "auto";
      example = 64;
      description = ''
        This option defines the maximum number of jobs that Nix will try to
        build in parallel. The default is auto, which means it will use all
        available logical cores. It is recommend to set it to the total
        number of logical cores in your system (e.g., 16 for two CPUs with 4
        cores each and hyper-threading).
      '';
    };

    nix.buildCores = mkOption {
      type = types.int;
      default = 0;
      example = 64;
      description = ''
        This option defines the maximum number of concurrent tasks during
        one build. It affects, e.g., -j option for make.
        The special value 0 means that the builder should use all
        available CPU cores in the system. Some builds may become
        non-deterministic with this option; use with care! Packages will
        only be affected if enableParallelBuilding is set for them.
      '';
    };

    nix.useSandbox = mkOption {
      type = types.either types.bool (types.enum ["relaxed"]);
      default = false;
      description = "
        If set, Nix will perform builds in a sandboxed environment that it
        will set up automatically for each build.  This prevents
        impurities in builds by disallowing access to dependencies
        outside of the Nix store.
      ";
    };

    nix.sandboxPaths = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "/dev" "/proc" ];
      description =
        ''
          Directories from the host filesystem to be included
          in the sandbox.
        '';
    };

    nix.extraOptions = mkOption {
      type = types.lines;
      default = "";
      example = ''
        gc-keep-outputs = true
        gc-keep-derivations = true
      '';
      description = "Additional text appended to <filename>nix.conf</filename>.";
    };

    nix.distributedBuilds = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to distribute builds to the machines listed in
        <option>nix.buildMachines</option>.

        NOTE: This requires services.nix-daemon.enable for a
        multi-user install.
      '';
    };

    nix.daemonNiceLevel = mkOption {
      type = types.int;
      default = 0;
      description = ''
        Nix daemon process priority. This priority propagates to build processes.
        0 is the default Unix process priority, 19 is the lowest.
      '';
    };

    nix.daemonIONice = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether the Nix daemon process should considered to be low priority when
        doing file system I/O.
      '';
    };

    nix.buildMachines = mkOption {
      type = types.listOf types.attrs;
      default = [];
      example = [
        { hostName = "voila.labs.cs.uu.nl";
          sshUser = "nix";
          sshKey = "/root/.ssh/id_buildfarm";
          system = "powerpc-darwin";
          maxJobs = 1;
        }
        { hostName = "linux64.example.org";
          sshUser = "buildfarm";
          sshKey = "/root/.ssh/id_buildfarm";
          system = "x86_64-linux";
          maxJobs = 2;
          supportedFeatures = [ "kvm" ];
          mandatoryFeatures = [ "perf" ];
        }
      ];
      description = ''
        This option lists the machines to be used if distributed
        builds are enabled (see
        <option>nix.distributedBuilds</option>).  Nix will perform
        derivations on those machines via SSH by copying the inputs
        to the Nix store on the remote machine, starting the build,
        then copying the output back to the local Nix store.  Each
        element of the list should be an attribute set containing
        the machine's host name (<varname>hostname</varname>), the
        user name to be used for the SSH connection
        (<varname>sshUser</varname>), the Nix system type
        (<varname>system</varname>, e.g.,
        <literal>"i686-linux"</literal>), the maximum number of
        jobs to be run in parallel on that machine
        (<varname>maxJobs</varname>), the path to the SSH private
        key to be used to connect (<varname>sshKey</varname>), a
        list of supported features of the machine
        (<varname>supportedFeatures</varname>) and a list of
        mandatory features of the machine
        (<varname>mandatoryFeatures</varname>). The SSH private key
        should not have a passphrase, and the corresponding public
        key should be added to
        <filename>~<replaceable>sshUser</replaceable>/authorized_keys</filename>
        on the remote machine.
      '';
    };

    # Environment variables for running Nix.
    nix.envVars = mkOption {
      type = types.attrs;
      internal = true;
      default = {};
      description = "Environment variables used by Nix.";
    };

    nix.readOnlyStore = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If set, NixOS will enforce the immutability of the Nix store
        by making <filename>/nix/store</filename> a read-only bind
        mount.  Nix will automatically make the store writable when
        needed.
      '';
    };

    nix.binaryCaches = mkOption {
      type = types.listOf types.str;
      example = [ https://cache.example.org/ ];
      description = ''
        List of binary cache URLs used to obtain pre-built binaries
        of Nix packages.
      '';
    };

    nix.trustedBinaryCaches = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ https://hydra.example.org/ ];
      description = ''
        List of binary cache URLs that non-root users can use (in
        addition to those specified using
        <option>nix.binaryCaches</option>) by passing
        <literal>--option binary-caches</literal> to Nix commands.
      '';
    };

    nix.requireSignedBinaryCaches = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If enabled (the default), Nix will only download binaries from binary caches if
        they are cryptographically signed with any of the keys listed in
        <option>nix.binaryCachePublicKeys</option>. If disabled, signatures are neither
        required nor checked, so it's strongly recommended that you use only
        trustworthy caches and https to prevent man-in-the-middle attacks.
      '';
    };

    nix.binaryCachePublicKeys = mkOption {
      type = types.listOf types.str;
      example = [ "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=" ];
      description = ''
        List of public keys used to sign binary caches. If
        <option>nix.requireSignedBinaryCaches</option> is enabled,
        then Nix will use a binary from a binary cache if and only
        if it is signed by <emphasis>any</emphasis> of the keys
        listed here. By default, only the key for
        <uri>cache.nixos.org</uri> is included.
      '';
    };

    nix.trustedUsers = mkOption {
      type = types.listOf types.str;
      default = [ "root" ];
      example = [ "root" "alice" "@wheel" ];
      description = ''
        A list of names of users that have additional rights when
        connecting to the Nix daemon, such as the ability to specify
        additional binary caches, or to import unsigned NARs. You
        can also specify groups by prefixing them with
        <literal>@</literal>; for instance,
        <literal>@wheel</literal> means all users in the wheel
        group.
      '';
    };

    nix.allowedUsers = mkOption {
      type = types.listOf types.str;
      default = [ "*" ];
      example = [ "@wheel" "@builders" "alice" "bob" ];
      description = ''
        A list of names of users (separated by whitespace) that are
        allowed to connect to the Nix daemon. As with
        <option>nix.trustedUsers</option>, you can specify groups by
        prefixing them with <literal>@</literal>. Also, you can
        allow all users by specifying <literal>*</literal>. The
        default is <literal>*</literal>. Note that trusted users are
        always allowed to connect.
      '';
    };

    nix.nixPath = mkOption {
      type = mkOptionType {
        name = "nix path";
        merge = loc: defs:
          let
            values = flatten (map (def:
              (map (x:
                if isAttrs x then (mapAttrsToList nameValuePair x)
                else if isString x then x
                else throw "The option value `${showOption loc}` in `${def.file}` is not a attset or string.")
                (if isList def.value then def.value else [def.value]))) defs);

            namedPaths = mapAttrsToList (n: v: "${n}=${(head v).value}")
              (zipAttrs
                (map (x: { "${x.name}" = { inherit (x) value; }; })
                (filter isAttrs values)));

            searchPaths = unique
              (filter isString values);
          in
            namedPaths ++ searchPaths;
      };
      default =
        [ # Include default path <darwin-config>.
          { darwin-config = "${config.environment.darwinConfig}"; }
          "/nix/var/nix/profiles/per-user/root/channels"
          "$HOME/.nix-defexpr/channels"
        ];
      example =
        [ { trunk = "/src/nixpkgs"; }
        ];
      description = ''
        The default Nix expression search path, used by the Nix
        evaluator to look up paths enclosed in angle brackets
        (e.g. <literal>&lt;nixpkgs&gt;</literal>).

        Named entries can be specified using an attribute set, if an
        entry is configured multiple times the value with the lowest
        ordering will be used.
      '';
    };
  };

  config = {

    warnings = [
      (mkIf (!config.services.activate-system.enable && cfg.distributedBuilds) "services.activate-system is not enabled, a reboot could cause distributed builds to stop working.")
      (mkIf (!cfg.distributedBuilds && cfg.buildMachines != []) "nix.distributedBuilds is not enabled, build machines won't be configured.")
    ];

    nix.binaryCaches = mkAfter [ https://cache.nixos.org/ ];
    nix.binaryCachePublicKeys = mkAfter [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];

    nix.nixPath = mkMerge [
      (mkIf (config.system.stateVersion < 2) (mkDefault
      [ "darwin=$HOME/.nix-defexpr/darwin"
        "darwin-config=$HOME/.nixpkgs/darwin-configuration.nix"
        "/nix/var/nix/profiles/per-user/root/channels"
      ]))
      (mkIf (config.system.stateVersion > 3) (mkOrder 1200
      [ { darwin-config = "${config.environment.darwinConfig}"; }
        "/nix/var/nix/profiles/per-user/root/channels"
        "$HOME/.nix-defexpr/channels"
      ]))
    ];


    nix.package = mkIf (config.system.stateVersion < 3)
      (mkDefault "/nix/var/nix/profiles/default");

    nix.version = mkIf (isDerivation cfg.package) cfg.package.version or "<unknown>";

    environment.systemPackages = mkIf (isDerivation cfg.package)
      [ cfg.package ];

    environment.etc."nix/nix.conf".source = nixConf;

    environment.etc."nix/nix.conf".knownSha256Hashes = [
      "c4ecc3d541c163c8fcc954ccae6b8cab28c973dc283fea5995c69aaabcdf785f"  # nix installer
    ];

    # List of machines for distributed Nix builds in the format
    # expected by build-remote.
    environment.etc."nix/machines" =
      { enable = cfg.buildMachines != [];
        text =
          concatMapStrings (machine:
            "${if machine ? sshUser then "${machine.sshUser}@" else ""}${machine.hostName} "
            + machine.system or (concatStringsSep "," machine.systems)
            + " ${machine.sshKey or "-"} ${toString machine.maxJobs or 1} "
            + toString (machine.speedFactor or 1)
            + " "
            + concatStringsSep "," (machine.mandatoryFeatures or [] ++ machine.supportedFeatures or [])
            + " "
            + concatStringsSep "," machine.mandatoryFeatures or []
            + "\n"
          ) cfg.buildMachines;
      };

    nix.envVars =
      optionalAttrs (!isNix20) {
        NIX_CONF_DIR = "/etc/nix";

        # Enable the copy-from-other-stores substituter, which allows
        # builds to be sped up by copying build results from remote
        # Nix stores.  To do this, mount the remote file system on a
        # subdirectory of /run/nix/remote-stores.
        NIX_OTHER_STORES = "/run/nix/remote-stores/*/nix";
      }
      // optionalAttrs cfg.distributedBuilds {
        NIX_CURRENT_LOAD = "/run/nix/current-load";
      }
      // optionalAttrs (cfg.distributedBuilds && !isNix20) {
        NIX_BUILD_HOOK = "${cfg.package}/libexec/nix/build-remote.pl";
        NIX_REMOTE_SYSTEMS = "/etc/nix/machines";
      };

    environment.extraInit = optionalString (!isNix20) ''
      # Set up secure multi-user builds: non-root users build through the
      # Nix daemon.
      if [ ! -w /nix/var/nix/db ]; then
          export NIX_REMOTE=daemon
      fi
    '';

    # Set up the environment variables for running Nix.
    environment.variables = cfg.envVars //
      { NIX_PATH = concatStringsSep ":" cfg.nixPath;
      };

    system.activationScripts.nix.text = mkIf cfg.distributedBuilds ''
      if [ ! -d ${cfg.envVars.NIX_CURRENT_LOAD} ]; then
          mkdir -p ${cfg.envVars.NIX_CURRENT_LOAD}
      fi
    '';

    system.activationScripts.nix-daemon.text = mkIf cfg.useDaemon ''
      if ! diff /etc/nix/nix.conf /run/current-system/etc/nix/nix.conf &> /dev/null; then
          echo "reloading nix-daemon..." >&2
          launchctl kill HUP system/org.nixos.nix-daemon
      fi
      while ! nix-store --store daemon -q --hash ${pkgs.stdenv.shell} &>/dev/null; do
          echo "waiting for nix-daemon" >&2
          launchctl kickstart system/org.nixos.nix-daemon
      done
    '';

  };
}
