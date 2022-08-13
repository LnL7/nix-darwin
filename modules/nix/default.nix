{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.nix;

  nixPackage = cfg.package.out;

  isNixAtLeast = versionAtLeast (getVersion nixPackage);

  nixConf =
    assert isNixAtLeast "2.2";
    let

      mkValueString = v:
        if v == null then ""
        else if isInt v then toString v
        else if isBool v then boolToString v
        else if isFloat v then floatToString v
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
        # your NixOS configuration, typically
        # /etc/nixos/configuration.nix.  Do not edit it!
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

in

{
  imports = [
    (mkRemovedOptionModule [ "nix" "profile" ] "Use `nix.package` instead.")
    (mkRemovedOptionModule [ "nix" "version" ] "Consider using `nix.package.version` instead.")
  ] ++ mapAttrsToList (oldConf: newConf: mkRenamedOptionModule [ "nix" oldConf ] [ "nix" "settings" newConf ]) legacyConfMappings;

  ###### interface

  options = {

    nix = {

      package = mkOption {
        type = types.package;
        default = pkgs.nix;
        defaultText = literalExpression "pkgs.nix";
        description = ''
          This option specifies the Nix package instance to use throughout the system.
        '';
      };

      # Not in NixOS module
      useDaemon = mkOption {
        type = types.bool;
        default = false;
        description = "
          If set, Nix will use the daemon to perform operations.
          Use this instead of services.nix-daemon.enable if you don't wan't the
          daemon service to be managed for you.
        ";
      };

      distributedBuilds = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to distribute builds to the machines listed in
          <option>nix.buildMachines</option>.

          NOTE: This requires services.nix-daemon.enable for a
          multi-user install.
        '';
      };

      # Not in NixOS module
      daemonNiceLevel = mkOption {
        type = types.int;
        default = 0;
        description = ''
          Nix daemon process priority. This priority propagates to build processes.
          0 is the default Unix process priority, 19 is the lowest.
        '';
      };

      # Not in NixOS module
      daemonIONice = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether the Nix daemon process should considered to be low priority when
          doing file system I/O.
        '';
      };

      buildMachines = mkOption {
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
      envVars = mkOption {
        type = types.attrs;
        internal = true;
        default = {};
        description = "Environment variables used by Nix.";
      };

      readOnlyStore = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If set, NixOS will enforce the immutability of the Nix store
          by making <filename>/nix/store</filename> a read-only bind
          mount.  Nix will automatically make the store writable when
          needed.
        '';
      };

      nixPath = mkOption {
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

      checkConfig = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If enabled (the default), checks for data type mismatches and that Nix
          can parse the generated nix.conf.
        '';
      };

      registry = mkOption {
        type = types.attrsOf (types.submodule (
          let
            inputAttrs = types.attrsOf (types.oneOf [types.str types.int types.bool types.package]);
          in
          { config, name, ... }:
          { options = {
              from = mkOption {
                type = inputAttrs;
                example = { type = "indirect"; id = "nixpkgs"; };
                description = "The flake reference to be rewritten.";
              };
              to = mkOption {
                type = inputAttrs;
                example = { type = "github"; owner = "my-org"; repo = "my-nixpkgs"; };
                description = "The flake reference to which <option>from></option> is to be rewritten.";
              };
              flake = mkOption {
                type = types.unspecified;
                default = null;
                example = literalExpression "nixpkgs";
                description = ''
                  The flake input to which <option>from></option> is to be rewritten.
                '';
              };
              exact = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether the <option>from</option> reference needs to match exactly. If set,
                  a <option>from</option> reference like <literal>nixpkgs</literal> does not
                  match with a reference like <literal>nixpkgs/nixos-20.03</literal>.
                '';
              };
            };
            config = {
              from = mkDefault { type = "indirect"; id = name; };
              to = mkIf (config.flake != null)
                ({ type = "path";
                   path = config.flake.outPath;
                 } // lib.filterAttrs
                   (n: v: n == "lastModified" || n == "rev" || n == "revCount" || n == "narHash")
                   config.flake);
            };
          }
        ));
        default = {};
        description = ''
          A system-wide flake registry.
        '';
      };

      extraOptions = mkOption {
        type = types.lines;
        default = "";
        example = ''
          gc-keep-outputs = true
          gc-keep-derivations = true
        '';
        description = "Additional text appended to <filename>nix.conf</filename>.";
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = semanticConfType;

          options = {
            max-jobs = mkOption {
              type = types.either types.int (types.enum [ "auto" ]);
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

            auto-optimise-store = mkOption {
              type = types.bool;
              default = false;
              example = true;
              description = ''
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
              description = ''
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
              description = ''
                If set, Nix will perform builds in a sandboxed environment that it
                will set up automatically for each build. This prevents impurities
                in builds by disallowing access to dependencies outside of the Nix
                store by using network and mount namespaces in a chroot environment.
                This is enabled by default even though it has a possible performance
                impact due to the initial setup time of a sandbox for each build. It
                doesn't affect derivation hashes, so changing this option will not
                trigger a rebuild of packages.
              '';
            };

            extra-sandbox-paths = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "/dev" "/proc" ];
              description = ''
                Directories from the host filesystem to be included
                in the sandbox.
              '';
            };

            substituters = mkOption {
              type = types.listOf types.str;
              description = ''
                List of binary cache URLs used to obtain pre-built binaries
                of Nix packages.

                By default https://cache.nixos.org/ is added.
              '';
            };

            trusted-substituters = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "https://hydra.nixos.org/" ];
              description = ''
                List of binary cache URLs that non-root users can use (in
                addition to those specified using
                <option>nix.settings.substituters</option>) by passing
                <literal>--option binary-caches</literal> to Nix commands.
              '';
            };

            require-sigs = mkOption {
              type = types.bool;
              default = true;
              description = ''
                If enabled (the default), Nix will only download binaries from binary caches if
                they are cryptographically signed with any of the keys listed in
                <option>nix.settings.trusted-public-keys</option>. If disabled, signatures are neither
                required nor checked, so it's strongly recommended that you use only
                trustworthy caches and https to prevent man-in-the-middle attacks.
              '';
            };

            trusted-public-keys = mkOption {
              type = types.listOf types.str;
              example = [ "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=" ];
              description = ''
                List of public keys used to sign binary caches. If
                <option>nix.settings.trusted-public-keys</option> is enabled,
                then Nix will use a binary from a binary cache if and only
                if it is signed by <emphasis>any</emphasis> of the keys
                listed here. By default, only the key for
                <uri>cache.nixos.org</uri> is included.
              '';
            };

            trusted-users = mkOption {
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
              example = [ "@wheel" "@builders" "alice" "bob" ];
              description = ''
                A list of names of users (separated by whitespace) that are
                allowed to connect to the Nix daemon. As with
                <option>nix.settings.trusted-users</option>, you can specify groups by
                prefixing them with <literal>@</literal>. Also, you can
                allow all users by specifying <literal>*</literal>. The
                default is <literal>*</literal>. Note that trusted users are
                always allowed to connect.
              '';
            };
          };
        };
        default = { };
        example = literalExpression ''
          {
            use-sandbox = true;
            show-trace = true;

            system-features = [ "big-parallel" "kvm" "recursive-nix" ];
            sandbox-paths = { "/bin/sh" = "''${pkgs.busybox-sandbox-shell.out}/bin/busybox"; };
          }
        '';
        description = ''
          Configuration for Nix, see
          <link xlink:href="https://nixos.org/manual/nix/stable/#sec-conf-file"/> or
          <citerefentry>
            <refentrytitle>nix.conf</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry> for avalaible options.
          The value declared here will be translated directly to the key-value pairs Nix expects.
          </para>
          <para>
          You can use <command>nix-instantiate --eval --strict '&lt;nixpkgs/nixos&gt;' -A config.nix.settings</command>
          to view the current value. By default it is empty.
          </para>
          <para>
          Nix configurations defined under <option>nix.*</option> will be translated and applied to this
          option. In addition, configuration specified in <option>nix.extraOptions</option> which will be appended
          verbatim to the resulting config file.
        '';
      };
    };
  };


  ###### implementation

  config = {

    warnings = [
      (mkIf (!config.services.activate-system.enable && cfg.distributedBuilds) "services.activate-system is not enabled, a reboot could cause distributed builds to stop working.")
      (mkIf (!cfg.distributedBuilds && cfg.buildMachines != []) "nix.distributedBuilds is not enabled, build machines won't be configured.")
    ];

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

    environment.systemPackages =
      [
        nixPackage
        pkgs.nix-info
      ]
      ++ optional (config.programs.bash.enableCompletion) pkgs.nix-bash-completions;

    environment.etc."nix/nix.conf".source = nixConf;

    # Not in NixOS module
    environment.etc."nix/nix.conf".knownSha256Hashes = [
      "7c2d80499b39256b03ee9abd3d6258343718306aca8d472c26ac32c9b0949093"  # nix installer
      "19299897fa312d9d32b3c968c2872dd143085aa727140cec51f57c59083e93b9"
      "c4ecc3d541c163c8fcc954ccae6b8cab28c973dc283fea5995c69aaabcdf785f"
    ];

    environment.etc."nix/registry.json".text = builtins.toJSON {
      version = 2;
      flakes = mapAttrsToList (n: v: { inherit (v) from to exact; }) cfg.registry;
    };

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

    environment.extraInit = ''
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
