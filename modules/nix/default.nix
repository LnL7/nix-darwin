# Based off: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/nix-daemon.nix
# When making changes please try to keep it in sync and keep the diff NixOS module clean.
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.nix;

  nixPackage = cfg.package.out;

  isNixAtLeast = versionAtLeast (getVersion nixPackage);

  makeNixBuildUser = nr: {
    name = "_nixbld${toString nr}";
    value = {
      description = "Nix build user ${toString nr}";

      /*
        For consistency with the setgid(2), setuid(2), and setgroups(2)
        calls in `libstore/build.cc', don't add any supplementary group
        here except "nixbld".
      */
      uid = builtins.add config.ids.uids.nixbld nr;
      gid = config.ids.gids.nixbld;
    };
  };

  nixbldUsers = listToAttrs (map makeNixBuildUser (range 1 cfg.nrBuildUsers));

  nixConf =
    assert isNixAtLeast "2.2";
    let

      mkValueString = v:
        if v == null then ""
        else if isInt v then toString v
        else if isBool v then boolToString v
        else if isFloat v then strings.floatToString v
        else if isList v then toString v
        else if isDerivation v then toString v
        else if builtins.isPath v then toString v
        else if isString v then v
        else if isCoercibleToString v then toString v
        else abort "The nix conf value: ${toPretty {} v} can not be encoded";

      mkKeyValue = k: v: "${escape [ "=" ] k} = ${mkValueString v}";

      mkKeyValuePairs = attrs: concatStringsSep "\n" (mapAttrsToList mkKeyValue attrs);

    in
    pkgs.writeTextFile {
      name = "nix.conf";
      text = ''
        # WARNING: this file is generated from the nix.* options in
        # your nix-darwin configuration. Do not edit it!
        ${mkKeyValuePairs cfg.settings}
        ${cfg.extraOptions}
      '';
      checkPhase =
        if pkgs.stdenv.hostPlatform != pkgs.stdenv.buildPlatform then ''
          echo "Ignoring validation for cross-compilation"
        ''
        else ''
          echo "Validating generated nix.conf"
          ln -s $out ./nix.conf
          set -e
          set +o pipefail
          NIX_CONF_DIR=$PWD \
            ${cfg.package}/bin/nix show-config ${optionalString (isNixAtLeast "2.3pre") "--no-net"} \
              ${optionalString (isNixAtLeast "2.4pre") "--option experimental-features nix-command"} \
            |& sed -e 's/^warning:/error:/' \
            | (! grep '${if cfg.checkConfig then "^error:" else "^error: unknown setting"}')
          set -o pipefail
        '';
    };

  legacyConfMappings = {
    useSandbox = "sandbox";
    buildCores = "cores";
    maxJobs = "max-jobs";
    sandboxPaths = "extra-sandbox-paths";
    binaryCaches = "substituters";
    trustedBinaryCaches = "trusted-substituters";
    binaryCachePublicKeys = "trusted-public-keys";
    autoOptimiseStore = "auto-optimise-store";
    requireSignedBinaryCaches = "require-sigs";
    trustedUsers = "trusted-users";
    allowedUsers = "allowed-users";
    # systemFeatures = "system-features";
  };

  semanticConfType = with types;
    let
      confAtom = nullOr
        (oneOf [
          bool
          int
          float
          str
          path
          package
        ]) // {
        description = "Nix config atom (null, bool, int, float, str, path or package)";
      };
    in
    attrsOf (either confAtom (listOf confAtom));

  # Not in NixOS module
  nixPathType = mkOptionType {
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

in

{
  imports =
    let
      altOption = alt: "No `nix-darwin` equivalent to this NixOS option, consider using `${alt}` instead.";
      consider = alt: "Consider using `${alt}` instead.";
    in
    [
      # Only ever in NixOS
      (mkRemovedOptionModule [ "nix" "enable" ] "No `nix-darwin` equivalent to this NixOS option.")
      (mkRemovedOptionModule [ "nix" "daemonCPUSchedPolicy" ] (altOption "nix.daemonProcessType"))
      (mkRemovedOptionModule [ "nix" "daemonIOSchedClass" ] (altOption "nix.daemonProcessType"))
      (mkRemovedOptionModule [ "nix" "daemonIOSchedPriority" ] (altOption "nix.daemonIOLowPriority"))
      (mkRemovedOptionModule [ "nix" "readOnlyStore" ] "No `nix-darwin` equivalent to this NixOS option.")

      # Option changes in `nix-darwin`
      (mkRemovedOptionModule [ "nix" "profile" ] "Use `nix.package` instead.")
      (mkRemovedOptionModule [ "nix" "version" ] (consider "nix.package.version"))
      (mkRenamedOptionModule [ "users" "nix" "configureBuildUsers" ] [ "nix" "configureBuildUsers" ])
      (mkRenamedOptionModule [ "users" "nix" "nrBuildUsers" ] [ "nix" "nrBuildUsers" ])
      (mkRenamedOptionModule [ "nix" "daemonIONice" ] [ "nix" "daemonIOLowPriority" ])
      (mkRemovedOptionModule [ "nix" "daemonNiceLevel" ] (consider "nix.daemonProcessType"))
    ] ++ mapAttrsToList (oldConf: newConf: mkRenamedOptionModule [ "nix" oldConf ] [ "nix" "settings" newConf ]) legacyConfMappings;

  ###### interface

  options = {

    nix = {

      package = mkOption {
        type = types.package;
        default = pkgs.nix;
        defaultText = literalExpression "pkgs.nix";
        description = lib.mdDoc ''
          This option specifies the Nix package instance to use throughout the system.
        '';
      };

      # Not in NixOS module
      useDaemon = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          If set, Nix will use the daemon to perform operations.
          Use this instead of services.nix-daemon.enable if you don't want the
          daemon service to be managed for you.
        '';
      };

      distributedBuilds = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether to distribute builds to the machines listed in
          {option}`nix.buildMachines`.

          NOTE: This requires services.nix-daemon.enable for a
          multi-user install.
        '';
      };

      # Not in NixOS module
      daemonProcessType = mkOption {
        type = types.enum [ "Background" "Standard" "Adaptive" "Interactive" ];
        default = "Standard";
        description = lib.mdDoc ''
          Nix daemon process resource limits class. These limits propagate to
          build processes. `Standard` is the default process type
          and will apply light resource limits, throttling its CPU usage and I/O
          bandwidth.

          See {command}`man launchd.plist` for explanation of other
          process types.
        '';
      };

      # Not in NixOS module
      daemonIOLowPriority = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether the Nix daemon process should considered to be low priority when
          doing file system I/O.
        '';
      };

      buildMachines = mkOption {
        type = types.listOf (types.submodule {
          options = {
            hostName = mkOption {
              type = types.str;
              example = "nixbuilder.example.org";
              description = lib.mdDoc ''
                The hostname of the build machine.
              '';
            };
            protocol = mkOption {
              type = types.enum [ null "ssh" "ssh-ng" ];
              default = "ssh";
              example = "ssh-ng";
              description = lib.mdDoc ''
                The protocol used for communicating with the build machine.
                Use `ssh-ng` if your remote builder and your
                local Nix version support that improved protocol.

                Use `null` when trying to change the special localhost builder
                without a protocol which is for example used by hydra.
              '';
            };
            system = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "x86_64-linux";
              description = lib.mdDoc ''
                The system type the build machine can execute derivations on.
                Either this attribute or {var}`systems` must be
                present, where {var}`system` takes precedence if
                both are set.
              '';
            };
            systems = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "x86_64-linux" "aarch64-linux" ];
              description = lib.mdDoc ''
                The system types the build machine can execute derivations on.
                Either this attribute or {var}`system` must be
                present, where {var}`system` takes precedence if
                both are set.
              '';
            };
            sshUser = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "builder";
              description = lib.mdDoc ''
                The username to log in as on the remote host. This user must be
                able to log in and run nix commands non-interactively. It must
                also be privileged to build derivations, so must be included in
                {option}`nix.settings.trusted-users`.
              '';
            };
            sshKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "/root/.ssh/id_buildhost_builduser";
              description = lib.mdDoc ''
                The path to the SSH private key with which to authenticate on
                the build machine. The private key must not have a passphrase.
                If null, the building user (root on NixOS machines) must have an
                appropriate ssh configuration to log in non-interactively.

                Note that for security reasons, this path must point to a file
                in the local filesystem, *not* to the nix store.
              '';
            };
            maxJobs = mkOption {
              type = types.int;
              default = 1;
              description = lib.mdDoc ''
                The number of concurrent jobs the build machine supports. The
                build machine will enforce its own limits, but this allows hydra
                to schedule better since there is no work-stealing between build
                machines.
              '';
            };
            speedFactor = mkOption {
              type = types.int;
              default = 1;
              description = lib.mdDoc ''
                The relative speed of this builder. This is an arbitrary integer
                that indicates the speed of this builder, relative to other
                builders. Higher is faster.
              '';
            };
            mandatoryFeatures = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "big-parallel" ];
              description = lib.mdDoc ''
                A list of features mandatory for this builder. The builder will
                be ignored for derivations that don't require all features in
                this list. All mandatory features are automatically included in
                {var}`supportedFeatures`.
              '';
            };
            supportedFeatures = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "kvm" "big-parallel" ];
              description = lib.mdDoc ''
                A list of features supported by this builder. The builder will
                be ignored for derivations that require features not in this
                list.
              '';
            };
            publicHostKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = lib.mdDoc ''
                The (base64-encoded) public host key of this builder. The field
                is calculated via {command}`base64 -w0 /etc/ssh/ssh_host_type_key.pub`.
                If null, SSH will use its regular known-hosts file when connecting.
              '';
            };
          };
        });
        default = [ ];
        description = lib.mdDoc ''
          This option lists the machines to be used if distributed builds are
          enabled (see {option}`nix.distributedBuilds`).
          Nix will perform derivations on those machines via SSH by copying the
          inputs to the Nix store on the remote machine, starting the build,
          then copying the output back to the local Nix store.
        '';
      };

      # Environment variables for running Nix.
      envVars = mkOption {
        type = types.attrs;
        internal = true;
        default = { };
        description = lib.mdDoc "Environment variables used by Nix.";
      };

      # Not in NixOS module
      configureBuildUsers = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Enable configuration for nixbld group and users.
        '';
      };

      nrBuildUsers = mkOption {
        type = types.int;
        description = lib.mdDoc ''
          Number of `nixbld` user accounts created to
          perform secure concurrent builds.  If you receive an error
          message saying that “all build users are currently in use”,
          you should increase this value.
        '';
      };

      # Definition differs substantially from NixOS module
      nixPath = mkOption {
        type = nixPathType;
        default = [
            # Include default path <darwin-config>.
            { darwin-config = "${config.environment.darwinConfig}"; }
            "/nix/var/nix/profiles/per-user/root/channels"
          ];
        description = lib.mdDoc ''
          The default Nix expression search path, used by the Nix
          evaluator to look up paths enclosed in angle brackets
          (e.g. `<nixpkgs>`).

          Named entries can be specified using an attribute set, if an
          entry is configured multiple times the value with the lowest
          ordering will be used.
        '';
      };

      checkConfig = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          If enabled (the default), checks for data type mismatches and that Nix
          can parse the generated nix.conf.
        '';
      };

      registry = mkOption {
        type = types.attrsOf (types.submodule (
          let
            referenceAttrs = with types; attrsOf (oneOf [
              str
              int
              bool
              package
            ]);
          in
          { config, name, ... }:
          {
            options = {
              from = mkOption {
                type = referenceAttrs;
                example = { type = "indirect"; id = "nixpkgs"; };
                description = lib.mdDoc "The flake reference to be rewritten.";
              };
              to = mkOption {
                type = referenceAttrs;
                example = { type = "github"; owner = "my-org"; repo = "my-nixpkgs"; };
                description = lib.mdDoc "The flake reference {option}`from` is rewritten to.";
              };
              flake = mkOption {
                type = types.nullOr types.attrs;
                default = null;
                example = literalExpression "nixpkgs";
                description = lib.mdDoc ''
                  The flake input {option}`from` is rewritten to.
                '';
              };
              exact = mkOption {
                type = types.bool;
                default = true;
                description = lib.mdDoc ''
                  Whether the {option}`from` reference needs to match exactly. If set,
                  a {option}`from` reference like `nixpkgs` does not
                  match with a reference like `nixpkgs/nixos-20.03`.
                '';
              };
            };
            config = {
              from = mkDefault { type = "indirect"; id = name; };
              to = mkIf (config.flake != null) (mkDefault (
                {
                  type = "path";
                  path = config.flake.outPath;
                } // filterAttrs
                  (n: _: n == "lastModified" || n == "rev" || n == "revCount" || n == "narHash")
                  config.flake
              ));
            };
          }
        ));
        default = { };
        description = lib.mdDoc ''
          A system-wide flake registry.
        '';
      };

      extraOptions = mkOption {
        type = types.lines;
        default = "";
        example = ''
          keep-outputs = true
          keep-derivations = true
        '';
        description = lib.mdDoc "Additional text appended to {file}`nix.conf`.";
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = semanticConfType;

          options = {
            max-jobs = mkOption {
              type = types.either types.int (types.enum [ "auto" ]);
              default = "auto";
              example = 64;
              description = lib.mdDoc ''
                This option defines the maximum number of jobs that Nix will try to
                build in parallel. The default is auto, which means it will use all
                available logical cores. It is recommend to set it to the total
                number of logical cores in your system (e.g., 16 for two CPUs with 4
                cores each and hyper-threading).
              '';
            };

            auto-optimise-store = mkOption {
              type = types.bool;
              default = false;
              example = true;
              description = lib.mdDoc ''
                If set to true, Nix automatically detects files in the store that have
                identical contents, and replaces them with hard links to a single copy.
                This saves disk space. If set to false (the default), you can still run
                nix-store --optimise to get rid of duplicate files.
              '';
            };

            cores = mkOption {
              type = types.int;
              default = 0;
              example = 64;
              description = lib.mdDoc ''
                This option defines the maximum number of concurrent tasks during
                one build. It affects, e.g., -j option for make.
                The special value 0 means that the builder should use all
                available CPU cores in the system. Some builds may become
                non-deterministic with this option; use with care! Packages will
                only be affected if enableParallelBuilding is set for them.
              '';
            };

            sandbox = mkOption {
              type = types.either types.bool (types.enum [ "relaxed" ]);
              default = false;
              description = lib.mdDoc ''
                If set, Nix will perform builds in a sandboxed environment that it
                will set up automatically for each build. This prevents impurities
                in builds by disallowing access to dependencies outside of the Nix
                store by using network and mount namespaces in a chroot environment. It
                doesn't affect derivation hashes, so changing this option will not
                trigger a rebuild of packages.
              '';
            };

            extra-sandbox-paths = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "/dev" "/proc" ];
              description = lib.mdDoc ''
                Directories from the host filesystem to be included
                in the sandbox.
              '';
            };

            substituters = mkOption {
              type = types.listOf types.str;
              description = lib.mdDoc ''
                List of binary cache URLs used to obtain pre-built binaries
                of Nix packages.

                By default https://cache.nixos.org/ is added.
              '';
            };

            trusted-substituters = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "https://hydra.nixos.org/" ];
              description = lib.mdDoc ''
                List of binary cache URLs that non-root users can use (in
                addition to those specified using
                {option}`nix.settings.substituters`) by passing
                `--option binary-caches` to Nix commands.
              '';
            };

            require-sigs = mkOption {
              type = types.bool;
              default = true;
              description = lib.mdDoc ''
                If enabled (the default), Nix will only download binaries from binary caches if
                they are cryptographically signed with any of the keys listed in
                {option}`nix.settings.trusted-public-keys`. If disabled, signatures are neither
                required nor checked, so it's strongly recommended that you use only
                trustworthy caches and https to prevent man-in-the-middle attacks.
              '';
            };

            trusted-public-keys = mkOption {
              type = types.listOf types.str;
              example = [ "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=" ];
              description = lib.mdDoc ''
                List of public keys used to sign binary caches. If
                {option}`nix.settings.trusted-public-keys` is enabled,
                then Nix will use a binary from a binary cache if and only
                if it is signed by *any* of the keys
                listed here. By default, only the key for
                `cache.nixos.org` is included.
              '';
            };

            trusted-users = mkOption {
              type = types.listOf types.str;
              default = [ "root" ];
              example = [ "root" "alice" "@admin" ];
              description = lib.mdDoc ''
                A list of names of users that have additional rights when
                connecting to the Nix daemon, such as the ability to specify
                additional binary caches, or to import unsigned NARs. You
                can also specify groups by prefixing them with
                `@`; for instance,
                `@admin` means all users in the wheel
                group.
              '';
            };

            # Not implemented yet
            # system-features = mkOption {
            #   type = types.listOf types.str;
            #   example = [ "kvm" "big-parallel" "gccarch-skylake" ];
            #   description = ''
            #     The set of features supported by the machine. Derivations
            #     can express dependencies on system features through the
            #     <literal>requiredSystemFeatures</literal> attribute.

            #     By default, pseudo-features <literal>nixos-test</literal>, <literal>benchmark</literal>,
            #     and <literal>big-parallel</literal> used in Nixpkgs are set, <literal>kvm</literal>
            #     is also included in it is avaliable.
            #   '';
            # };

            allowed-users = mkOption {
              type = types.listOf types.str;
              default = [ "*" ];
              example = [ "@admin" "@builders" "alice" "bob" ];
              description = lib.mdDoc ''
                A list of names of users (separated by whitespace) that are
                allowed to connect to the Nix daemon. As with
                {option}`nix.settings.trusted-users`, you can specify groups by
                prefixing them with `@`. Also, you can
                allow all users by specifying `*`. The
                default is `*`. Note that trusted users are
                always allowed to connect.
              '';
            };
          };
        };
        default = { };
        description = lib.mdDoc ''
          Configuration for Nix, see
          <https://nixos.org/manual/nix/stable/#sec-conf-file>
          for avalaible options.
          The value declared here will be translated directly to the key-value pairs Nix expects.

          Nix configurations defined under {option}`nix.*` will be translated and applied to this
          option. In addition, configuration specified in {option}`nix.extraOptions` which will be appended
          verbatim to the resulting config file.
        '';
      };
    };
  };


  ###### implementation

  config = {
    environment.systemPackages =
      [
        nixPackage
        pkgs.nix-info
      ]
      ++ optional (config.programs.bash.enableCompletion) pkgs.nix-bash-completions;

    environment.etc."nix/nix.conf".source = nixConf;

    # Not in NixOS module
    environment.etc."nix/nix.conf".knownSha256Hashes = [
      "7c2d80499b39256b03ee9abd3d6258343718306aca8d472c26ac32c9b0949093"  # official Nix installer
      "19299897fa312d9d32b3c968c2872dd143085aa727140cec51f57c59083e93b9"
      "c4ecc3d541c163c8fcc954ccae6b8cab28c973dc283fea5995c69aaabcdf785f"
      "ef78f401a9b5a42fd15e967c50da384f99ec62f9dbc66ea38f1390b46b63e1ff"  # official Nix installer 2.0
      "c06b0c6080dd1d62e61a30cfad100c0cfed2d3bcd378e296632dc3b28b31dc69"  # official Nix installer as of 2.0.1
      "ff08c12813680da98c4240328f828647b67a65ba7aa89c022bd8072cba862cf1"  # official Nix installer as of 2.4
      "f3e03d851c240c1aa7daccd144ee929f0f5971982424c868c434eb6030e961d4"  # DeterminateSystems Nix installer 0.10.0
      "c6080216f2a170611e339c3f46e4e1d61aaf0d8b417ad93ade8d647da1382c11"  # DeterminateSystems Nix installer 0.14.0
      "97f4135d262ca22d65c9554aad795c10a4491fa61b67d9c2430f4d82bbfec9a2"  # DeterminateSystems Nix installer 0.15.1+
    ];

    environment.etc."nix/registry.json".text = builtins.toJSON {
      version = 2;
      flakes = mapAttrsToList (n: v: { inherit (v) from to exact; }) cfg.registry;
    };

    # List of machines for distributed Nix builds in the format
    # expected by build-remote.pl.
    environment.etc."nix/machines" = mkIf (cfg.buildMachines != [ ]) {
      text =
        concatMapStrings
          (machine:
            (concatStringsSep " " ([
              "${optionalString (machine.protocol != null) "${machine.protocol}://"}${optionalString (machine.sshUser != null) "${machine.sshUser}@"}${machine.hostName}"
              (if machine.system != null then machine.system else if machine.systems != [ ] then concatStringsSep "," machine.systems else "-")
              (if machine.sshKey != null then machine.sshKey else "-")
              (toString machine.maxJobs)
              (toString machine.speedFactor)
              (let res = (machine.supportedFeatures ++ machine.mandatoryFeatures);
               in if (res == []) then "-" else (concatStringsSep "," res))
              (let res = machine.mandatoryFeatures;
               in if (res == []) then "-" else (concatStringsSep "," machine.mandatoryFeatures))
            ]
            ++ optional (isNixAtLeast "2.4pre") (if machine.publicHostKey != null then machine.publicHostKey else "-")))
            + "\n"
          )
          cfg.buildMachines;
    };

    assertions =
      let
        badMachine = m: m.system == null && m.systems == [ ];

        # Not in NixOS module
        createdGroups = mapAttrsToList (n: v: v.name) config.users.groups;
        createdUsers = mapAttrsToList (n: v: v.name) config.users.users;
      in
      [
        {
          assertion = !(any badMachine cfg.buildMachines);
          message = ''
            At least one system type (via <varname>system</varname> or
              <varname>systems</varname>) must be set for every build machine.
              Invalid machine specifications:
          '' + "      " +
          (concatStringsSep "\n      "
            (map (m: m.hostName)
              (filter (badMachine) cfg.buildMachines)));
        }

        # Not in NixOS module
        { assertion = elem "nixbld" config.users.knownGroups -> elem "nixbld" createdGroups; message = "refusing to delete group nixbld in users.knownGroups, this would break nix"; }
        { assertion = elem "_nixbld1" config.users.knownGroups -> elem "_nixbld1" createdUsers; message = "refusing to delete user _nixbld1 in users.knownUsers, this would break nix"; }
        { assertion = config.users.groups ? "nixbld" -> config.users.groups.nixbld.members != []; message = "refusing to remove all members from nixbld group, this would break nix"; }
      ];

    # Not in NixOS module
    warnings = [
      (mkIf (!config.services.activate-system.enable && cfg.distributedBuilds) "services.activate-system is not enabled, a reboot could cause distributed builds to stop working.")
      (mkIf (!cfg.distributedBuilds && cfg.buildMachines != []) "nix.distributedBuilds is not enabled, build machines won't be configured.")
    ];

    # Not in NixOS module
    nix.nixPath = mkMerge [
      (mkIf (config.system.stateVersion < 2) (mkDefault
      [ "darwin=$HOME/.nix-defexpr/darwin"
        "darwin-config=$HOME/.nixpkgs/darwin-configuration.nix"
        "/nix/var/nix/profiles/per-user/root/channels"
      ]))
      (mkIf (config.system.stateVersion > 3) (mkOrder 1200
      [ { darwin-config = "${config.environment.darwinConfig}"; }
        "/nix/var/nix/profiles/per-user/root/channels"
      ]))
    ];

    # Set up the environment variables for running Nix.
    environment.variables = cfg.envVars // { NIX_PATH = cfg.nixPath; };

    environment.extraInit =
      ''
        if [ -e "$HOME/.nix-defexpr/channels" ]; then
          export NIX_PATH="$HOME/.nix-defexpr/channels''${NIX_PATH:+:$NIX_PATH}"
        fi
      '' +
      # Not in NixOS module
      ''
        # Set up secure multi-user builds: non-root users build through the
        # Nix daemon.
        if [ ! -w /nix/var/nix/db ]; then
            export NIX_REMOTE=daemon
        fi
      '';

    nix.nrBuildUsers = mkDefault (max 32 (if cfg.settings.max-jobs == "auto" then 0 else cfg.settings.max-jobs));

    users.users = mkIf cfg.configureBuildUsers nixbldUsers;

    # Not in NixOS module
    users.groups.nixbld = mkIf cfg.configureBuildUsers {
      description = "Nix build group for nix-daemon";
      gid = config.ids.gids.nixbld;
      members = attrNames nixbldUsers;
    };
    users.knownUsers =
      let nixbldUserNames = attrNames nixbldUsers;
      in
      mkIf cfg.configureBuildUsers (mkMerge [
        nixbldUserNames
        (map (removePrefix "_") nixbldUserNames) # delete old style nixbld users
      ]);
    users.knownGroups = mkIf cfg.configureBuildUsers [ "nixbld" ];

    # Unrelated to use in NixOS module
    system.activationScripts.nix-daemon.text = mkIf cfg.useDaemon ''
      if ! diff /etc/nix/nix.conf /run/current-system/etc/nix/nix.conf &> /dev/null || ! diff /etc/nix/machines /run/current-system/etc/nix/machines &> /dev/null; then
          echo "reloading nix-daemon..." >&2
          launchctl kill HUP system/org.nixos.nix-daemon
      fi
      while ! nix-store --store daemon -q --hash ${pkgs.stdenv.shell} &>/dev/null; do
          echo "waiting for nix-daemon" >&2
          launchctl kickstart system/org.nixos.nix-daemon
      done
    '';

    # Legacy configuration conversion.
    nix.settings = mkMerge [
      {
        trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
        substituters = mkAfter [ "https://cache.nixos.org/" ];

        # Not implemented yet
        # system-features = mkDefault (
        #   [ "nixos-test" "benchmark" "big-parallel" "kvm" ] ++
        #   optionals (pkgs.hostPlatform ? gcc.arch) (
        #     # a builder can run code for `gcc.arch` and inferior architectures
        #     [ "gccarch-${pkgs.hostPlatform.gcc.arch}" ] ++
        #     map (x: "gccarch-${x}") systems.architectures.inferiors.${pkgs.hostPlatform.gcc.arch}
        #   )
        # );
      }

      (mkIf (!cfg.distributedBuilds) { builders = null; })

      (mkIf (isNixAtLeast "2.3pre") { sandbox-fallback = false; })

      # Not in NixOS module
      (mkIf cfg.useDaemon { build-users-group = "nixbld"; })
    ];

  };

}
