{ config, lib, pkgs, ... }:
with lib;
let
  mkSvcName = name: "github-runner-${name}";
  mkStateDir = cfg: "/var/lib/github-runners/${cfg.name}";
  mkLogDir = cfg: "/var/log/github-runners/${cfg.name}";
  mkWorkDir = cfg: if (cfg.workDir != null) then cfg.workDir else "/var/lib/github-runners/_work/${cfg.name}";
in
{
  config.assertions = flatten (
    flip mapAttrsToList config.services.github-runners (name: cfg: map (mkIf cfg.enable) [
      {
        assertion = (cfg.user == null && cfg.group == null) || (cfg.user != null);
        message = "`services.github-runners.${name}`: Either set `user` and `group` to `null` to have nix-darwin manage them or set at least `user` explicitly";
      }
      {
        assertion = !cfg.noDefaultLabels || (cfg.extraLabels != [ ]);
        message = "`services.github-runners.${name}`: The `extraLabels` option is mandatory if `noDefaultLabels` is set";
      }
      {
        assertion = cfg.workDir == null || !(hasPrefix "/run/" cfg.workDir || hasPrefix "/var/run/" cfg.workDir || hasPrefix "/private/var/run/");
        message = "`services.github-runners.${name}`: `workDir` being inside /run is not supported";
      }
    ])
  );

  config.warnings = flatten (
    flip mapAttrsToList config.services.github-runners (name: cfg: map (mkIf cfg.enable) [
      (
        mkIf (hasPrefix builtins.storeDir cfg.tokenFile)
          "`services.github-runners.${name}`: `tokenFile` contains a secret but points to the world-readable Nix store."
      )
    ])
  );

  # Create the necessary directories and make the service user/group their owner
  # This has to happen *after* nix-darwin user creation and *before* any launchd service gets started.
  config.system.activationScripts = mkMerge (flip mapAttrsToList config.services.github-runners (name: cfg:
    let
      user = config.launchd.daemons.${mkSvcName name}.serviceConfig.UserName;
      group =
        if config.launchd.daemons.${mkSvcName name}.serviceConfig.GroupName != null
        then config.launchd.daemons.${mkSvcName name}.serviceConfig.GroupName
        else "";
    in
    {
      launchd = mkIf cfg.enable {
        text = mkBefore (''
          echo >&2 "setting up GitHub Runner '${cfg.name}'..."

          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${escapeShellArg (mkStateDir cfg)}
          ${pkgs.coreutils}/bin/chown ${user}:${group} ${escapeShellArg (mkStateDir cfg)}

          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${escapeShellArg (mkLogDir cfg)}
          ${pkgs.coreutils}/bin/chown ${user}:${group} ${escapeShellArg (mkLogDir cfg)}
        '' + optionalString (cfg.workDir == null) ''
          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${escapeShellArg (mkWorkDir cfg)}
          ${pkgs.coreutils}/bin/chown ${user}:${group} ${escapeShellArg (mkWorkDir cfg)}
        '');
      };
    }));

  config.launchd.daemons = flip mapAttrs' config.services.github-runners (name: cfg:
    let
      package = cfg.package.override (old: optionalAttrs (hasAttr "nodeRuntimes" old) { inherit (cfg) nodeRuntimes; });
      stateDir = mkStateDir cfg;
      logDir = mkLogDir cfg;
      workDir = mkWorkDir cfg;
    in
    nameValuePair
      (mkSvcName name)
      (mkIf cfg.enable {
        environment = {
          HOME = stateDir;
          RUNNER_ROOT = stateDir;
        } // cfg.extraEnvironment;

        # Minimal package set for `actions/checkout`
        path = (with pkgs; [
          bash
          coreutils
          git
          gnutar
          gzip
        ]) ++ [
          config.nix.package
        ] ++ cfg.extraPackages;

        script =
          let
            configure = pkgs.writeShellApplication {
              name = "configure-github-runner-${name}";
              text = /*bash*/''
                export RUNNER_ROOT

                args=(
                  --unattended
                  --disableupdate
                  --work ${escapeShellArg workDir}
                  --url ${escapeShellArg cfg.url}
                  --labels "${escapeShellArg (concatStringsSep "," cfg.extraLabels)}"
                  ${optionalString (cfg.name != null ) "--name ${escapeShellArg cfg.name}"}
                  ${optionalString cfg.replace "--replace"}
                  ${optionalString (cfg.runnerGroup != null) "--runnergroup ${escapeShellArg cfg.runnerGroup}"}
                  ${optionalString cfg.ephemeral "--ephemeral"}
                  ${optionalString cfg.noDefaultLabels "--no-default-labels"}
                )
                # If the token file contains a PAT (i.e., it starts with "ghp_" or "github_pat_"), we have to use the --pat option,
                # if it is not a PAT, we assume it contains a registration token and use the --token option
                token=$(<"${cfg.tokenFile}")
                if [[ "$token" =~ ^ghp_* ]] || [[ "$token" =~ ^github_pat_* ]]; then
                  args+=(--pat "$token")
                else
                  args+=(--token "$token")
                fi
                ${package}/bin/config.sh "''${args[@]}"
              '';
            };
          in
          ''
            echo "Configuring GitHub Actions Runner"

            # Always clean the working directory
            ${pkgs.findutils}/bin/find ${escapeShellArg workDir} -mindepth 1 -delete

            # Clean the $RUNNER_ROOT if we are in ephemeral mode
            if ${boolToString cfg.ephemeral}; then
              echo "Cleaning $RUNNER_ROOT"
              ${pkgs.findutils}/bin/find "$RUNNER_ROOT" -mindepth 1 -delete
            fi

            # If the `.runner` file does not exist, we assume the runner is not configured
            if [[ ! -f "$RUNNER_ROOT/.runner" ]]; then
              ${getExe configure}
            fi

            # Start the service
            ${package}/bin/Runner.Listener run --startuptype service
          '';

        serviceConfig = mkMerge [
          {
            GroupName = cfg.group;
            KeepAlive = {
              Crashed = false;
            } // mkIf cfg.ephemeral {
              SuccessfulExit = true;
            };
            ProcessType = "Interactive";
            RunAtLoad = true;
            StandardErrorPath = "${logDir}/launchd-stderr.log";
            StandardOutPath = "${logDir}/launchd-stdout.log";
            ThrottleInterval = 30;
            UserName = if (cfg.user != null) then cfg.user else "_github-runner";
            WatchPaths = [
              "/etc/resolv.conf"
              "/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"
              cfg.tokenFile
            ];
            WorkingDirectory = stateDir;
          }
          cfg.serviceOverrides
        ];
      }));

  # If any GitHub runner configuration has set both `user` and `group` set to `null`,
  # manage the user and group `_github-runner` through nix-darwin.
  config.users = mkIf (any (cfg: cfg.enable && cfg.user == null && cfg.group == null) (attrValues config.services.github-runners)) {
    users."_github-runner" = {
      createHome = false;
      isSystemUser = true;
      description = "GitHub Runner service user";
      gid = config.users.groups."_github-runner".gid;
      home = "/var/lib/github-runners";
      shell = "/bin/bash";
      uid = mkDefault 533;
    };
    knownUsers = [ "_github-runner" ];

    groups."_github-runner" = {
      gid = mkDefault 533;
      description = "GitHub Runner service user group";
    };
    knownGroups = [ "_github-runner" ];
  };
}
