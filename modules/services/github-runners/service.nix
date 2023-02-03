{ config
, lib
, pkgs

, cfg ? config.services.github-runner
, svcName
, currentConfigTokenFilename ? ".current-token"

, ...
}:

with lib;

let
  baseDir = "${config.users.users.github-runner.home}/${svcName}";
  workDir =  "${baseDir}/work";
  stateDir = "${baseDir}/state";
  logsDir = "${baseDir}/logs";
  # Does the following, sequentially:
  # - If the module configuration or the token has changed, purge the state directory,
  #   and create the current and the new token file with the contents of the configured
  #   token. While both files have the same content, only the later is accessible by
  #   the service user.
  # - Configure the runner using the new token file. When finished, delete it.
  # - Set up the directory structure by creating the necessary symlinks.
  setupScript =
    let
      # Wrapper script which expects the full path of the state, working and logs
      # directory as arguments. Overrides the respective systemd variables to provide
      # unambiguous directory names. This becomes relevant, for example, if the
      # caller overrides any of the StateDirectory=, RuntimeDirectory= or LogDirectory=
      # to contain more than one directory. This causes systemd to set the respective
      # environment variables with the path of all of the given directories, separated
      # by a colon.
      writeScript = name: lines: pkgs.writeShellScript "${svcName}-${name}.sh" ''
        set -euo pipefail
        set -x

        STATE_DIRECTORY="$1"
        WORK_DIRECTORY="$2"
        LOGS_DIRECTORY="$3"

        mkdir -p $STATE_DIRECTORY $WORK_DIRECTORY $LOGS_DIRECTORY

        ${lines}
      '';
      runnerRegistrationConfig = {
        name = svcName;
        inherit (cfg)
          tokenFile
          url
          runnerGroup
          extraLabels
          ephemeral
          baseDir;
      };
      newConfigPath = builtins.toFile "${svcName}-config.json" (builtins.toJSON runnerRegistrationConfig);
      currentConfigPath = "$STATE_DIRECTORY/.nixos-current-config.json";
      newConfigTokenPath = "$STATE_DIRECTORY/.new-token";
      currentConfigTokenPath = "$STATE_DIRECTORY/${currentConfigTokenFilename}";

      runnerCredFiles = [
        ".credentials"
        ".credentials_rsaparams"
        ".runner"
      ];
      unconfigureRunner = writeScript "unconfigure" ''
        copy_tokens() {
          # Copy the configured token file to the state dir and allow the service user to read the file
          install --mode=666 ${escapeShellArg cfg.tokenFile} "${newConfigTokenPath}"
          # Also copy current file to allow for a diff on the next start
          install --mode=600 ${escapeShellArg cfg.tokenFile} "${currentConfigTokenPath}"
        }
        clean_state() {
          ${pkgs.findutils}/bin/find "$STATE_DIRECTORY/" -mindepth 1 -delete
          copy_tokens
        }
        diff_config() {
          changed=0
          # Check for module config changes
          [[ -f "${currentConfigPath}" ]] \
            && ${pkgs.diffutils}/bin/diff -q '${newConfigPath}' "${currentConfigPath}" >/dev/null 2>&1 \
            || changed=1
          # Also check the content of the token file
          [[ -f "${currentConfigTokenPath}" ]] \
            && ${pkgs.diffutils}/bin/diff -q "${currentConfigTokenPath}" ${escapeShellArg cfg.tokenFile} >/dev/null 2>&1 \
            || changed=1
          # If the config has changed, remove old state and copy tokens
          if [[ "$changed" -eq 1 ]]; then
            echo "Config has changed, removing old runner state."
            echo "The old runner will still appear in the GitHub Actions UI." \
                  "You have to remove it manually."
            clean_state
          fi
        }
        if [[ "${optionalString cfg.ephemeral "1"}" ]]; then
          # In ephemeral mode, we always want to start with a clean state
          clean_state
        elif [[ "$(ls -A "$STATE_DIRECTORY")" ]]; then
          # There are state files from a previous run; diff them to decide if we need a new registration
          diff_config
        else
          # The state directory is entirely empty which indicates a first start
          copy_tokens
        fi
      '';
      configureRunner = writeScript "configure" ''
        if [[ -e "${newConfigTokenPath}" ]]; then
          echo "Configuring GitHub Actions Runner"
          args=(
            --unattended
            --disableupdate
            --work "$WORK_DIRECTORY"
            --url ${escapeShellArg cfg.url}
            --labels ${escapeShellArg (concatStringsSep "," cfg.extraLabels)}
            --name ${escapeShellArg svcName}
            ${optionalString cfg.replace "--replace"}
            ${optionalString (cfg.runnerGroup != null) "--runnergroup ${escapeShellArg cfg.runnerGroup}"}
            ${optionalString cfg.ephemeral "--ephemeral"}
          )
          # If the token file contains a PAT (i.e., it starts with "ghp_" or "github_pat_"), we have to use the --pat option,
          # if it is not a PAT, we assume it contains a registration token and use the --token option
          token=$(<"${newConfigTokenPath}")
          if [[ "$token" =~ ^ghp_* ]] || [[ "$token" =~ ^github_pat_* ]]; then
            args+=(--pat "$token")
          else
            args+=(--token "$token")
          fi
          ${cfg.package}/bin/config.sh "''${args[@]}"
          # Move the automatically created _diag dir to the logs dir
          mkdir -p  "$STATE_DIRECTORY/_diag"
          cp    -r  "$STATE_DIRECTORY/_diag/." "$LOGS_DIRECTORY/"
          rm    -rf "$STATE_DIRECTORY/_diag/"
          # Cleanup token from config
          rm "${newConfigTokenPath}"
          # Symlink to new config
          ln -s '${newConfigPath}' "${currentConfigPath}"
        fi
      '';
      setupWorkDir = writeScript "setup-work-dirs" ''
        # Cleanup previous service
        ${pkgs.findutils}/bin/find -H "$WORK_DIRECTORY" -mindepth 1 -delete

        # Link _diag dir
        ln -s "$LOGS_DIRECTORY" "$WORK_DIRECTORY/_diag"

        # Link the runner credentials to the work dir
        ln -s "$STATE_DIRECTORY"/{${lib.concatStringsSep "," runnerCredFiles}} "$WORK_DIRECTORY/"
      '';
    in
      lib.concatStringsSep "\n"
      (map (x: "${x} ${escapeShellArgs [ stateDir workDir logsDir ]}") [
        unconfigureRunner
        configureRunner
        setupWorkDir
      ]);
in {
  script = ''
    set -x
    ${setupScript}
    ${cfg.package}/bin/Runner.Listener run --startuptype service
  '';

  path = config.environment.systemPackages;

  environment =
    {
      NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      RUNNER_ROOT = stateDir;
      USER = "github-runner";
      HOME = baseDir;
    }
    // cfg.extraEnvironment;

  serviceConfig.UserName = "github-runner";
  serviceConfig.GroupName = "github-runner";
  serviceConfig.WorkingDirectory = baseDir;

  serviceConfig.KeepAlive = true;
  serviceConfig.RunAtLoad = true;
  serviceConfig.ThrottleInterval = 30;
  serviceConfig.ProcessType = "Interactive";
  serviceConfig.StandardErrorPath = "${baseDir}/runner-logs";
  serviceConfig.StandardOutPath = "${baseDir}/runner-logs";
  serviceConfig.WatchPaths = [
    cfg.tokenFile
    "/etc/resolv.conf"
    "/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"
  ];
}
