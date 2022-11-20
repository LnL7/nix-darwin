{ config, lib, pkgs, ... }:
let
  mkSvcName = name: "github-runner-${name}";
  mkRootDir = name: "${config.users.users.github-runner.home}/.github-runner/${name}";
  mkWorkDir = name: "${mkRootDir name}/_work";
in
with lib;
{
  launchd.daemons = flip mapAttrs' config.services.github-runners (name: cfg:
    nameValuePair
      (mkSvcName name)
      (mkIf cfg.enable {
        environment = {
          RUNNER_ROOT = mkRootDir name;
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

        script = ''
          echo "Configuring GitHub Actions Runner"
          mkdir -p ${escapeShellArg (mkRootDir name)}
          cd ${escapeShellArg (mkRootDir name)}

          args=(
            --unattended
            --disableupdate
            --work ${escapeShellArg (mkWorkDir name)}
            --url ${escapeShellArg cfg.url}
            --labels ${escapeShellArg (concatStringsSep "," cfg.extraLabels)}
            --name ${escapeShellArg cfg.name}
            ${optionalString cfg.replace "--replace"}
            ${optionalString (cfg.runnerGroup != null) "--runnergroup ${escapeShellArg cfg.runnerGroup}"}
            ${optionalString cfg.ephemeral "--ephemeral"}
          )
          # If the token file contains a PAT (i.e., it starts with "ghp_" or "github_pat_"), we have to use the --pat option,
          # if it is not a PAT, we assume it contains a registration token and use the --token option
          token=$(<"${cfg.tokenFile}")
          if [[ "$token" =~ ^ghp_* ]] || [[ "$token" =~ ^github_pat_* ]]; then
            args+=(--pat "$token")
          else
            args+=(--token "$token")
          fi
          ${cfg.package}/bin/config.sh "''${args[@]}"

          # Start the service
          ${cfg.package}/bin/Runner.Listener run --startuptype service
        '';

        serviceConfig = mkMerge [
          {
            KeepAlive = {
              Crashed = false;
            } // mkIf cfg.ephemeral {
              SuccessfulExit = true;
            };
            GroupName = "github-runner";
            ProcessType = "Interactive";
            RunAtLoad = true;
            ThrottleInterval = 30;
            UserName = "github-runner";
            WatchPaths = [
              "/etc/resolv.conf"
              "/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"
            ];
            WorkingDirectory = config.users.users.github-runner.home;
          }
          cfg.serviceOverrides
        ];
      }));
}
