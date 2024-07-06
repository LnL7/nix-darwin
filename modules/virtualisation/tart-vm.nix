{ config, pkgs, lib, ... }:

let
  ipsw = pkgs.callPackage ../../pkgs/ipsw { };
in {
  options = with lib; {
    virtualisation.initialUser = mkOption {
      type = types.str;
      default = if builtins.length (builtins.attrNames config.users.users) > 0 then builtins.elemAt (naturalSort (builtins.attrNames config.users.users)) 0 else "admin";
      defaultText = literalExpression ''
        if builtins.length (builtins.attrNames config.users.users) > 0 then builtins.elemAt (lib.naturalSort (builtins.attrNames config.users.users)) 0 else "admin";
      '';
      description = mdDoc ''
        The user to create the VM with.

        This defaults to the first user defined in `users.users`, otherwise it will default to `admin`.
      '';
    };

    virtualisation.diskSize = mkOption {
      type = types.ints.positive;
      default = 30;
      description = mdDoc ''
        The disk size in gigabytes of the virtual machine.

        15GiB is the minimum for a macOS install
      '';
    };

    virtualisation.macOSVersion = mkOption {
      type = types.enum (builtins.attrNames ipsw);
      default = "13.4";
      description = mdDoc ''
        The version of macOS that should be installed inside the virtual machine.

        You can download the IPSW file using the fetch script:

          nix run nix-darwin#ipsw.\"13.4\".fetchScript
      '';
    };
  };

  config = let
    cfg = config.virtualisation;

    nix-installer = pkgs.callPackage ../../pkgs/nix-installer { };

    timeout = "${lib.getBin pkgs.coreutils}/bin/timeout";

    username = cfg.initialUser;
    user = config.users.users.${username};

    sshOptions = ''-o "UserKnownHostsFile=$TART_HOME/known_hosts" -F /dev/null -i "$TART_HOME/id_ed25519"'';
    sshDestination = ''${sshOptions} "${username}@$VM_IP"'';

  in {
    environment.etc."nix/nix.conf".force = true;

    users.users.admin.name = lib.mkDefault "admin";

    system.build.ipsw = ipsw.${cfg.macOSVersion};

    system.build.vm = (pkgs.writeShellApplication {
      name = "run-darwin-vm";
      runtimeInputs = [ pkgs.tart pkgs.jq pkgs.vncdo pkgs.passh pkgs.retry ];
      text = ''
        set -x

        # Allows trap ERR to work with `set -e`
        set -E

        # For job control
        set -m

        unset SSH_AUTH_SOCK

        export TART_HOME=$PWD/darwin-vm
        STATE_FILE=$TART_HOME/darwin-vm.state

        # states: null, uninstalled, macos-possibly-finished, macos-installed, installation-complete
        VM_STATE=$(cat "$STATE_FILE" || echo "null")
        VM_RUNNING=$(tart list --format json | jq '.[] | select(.Name == "darwin-vm") | .Running')

        VM_PASS="admin"

        if [[ "$VM_STATE" != "installation-complete" ]]; then
          if [[ "$VM_RUNNING" == "true" ]]; then
            tart stop darwin-vm
          fi

          if [[ "$VM_STATE" != "uninstalled" && "$VM_STATE" != "null" ]]; then
            tart delete darwin-vm
          fi

          if ! tart list | grep darwin-vm >/dev/null 2>&1; then
            tart create darwin-vm --from-ipsw ${ipsw.${cfg.macOSVersion}} --disk-size ${toString cfg.diskSize}
            echo uninstalled > "$STATE_FILE"

            # To avoid running into "Failed to lock auxiliary storage." we need to wait a bit after creating a VM
            sleep 5
          fi

          (tart run --vnc-experimental --no-graphics darwin-vm | tee "$TART_HOME/tart.out") &

          # Give it time to start VM and VNC server
          sleep 5
          VNC_URL=$(grep --only 'vnc://.*\d' "$TART_HOME/tart.out")
          IFS=":" read -r -a VNC_DETAILS <<< "''${VNC_URL//@/:}"
          VNC_PASSWORD=''${VNC_DETAILS[2]}
          VNC_ADDRESS=''${VNC_DETAILS[3]}
          VNC_PORT=''${VNC_DETAILS[4]}

          # If we fail during installation, pass control back to `tart run` so users can kill the VM with Ctrl-C
          trap onInstallFail ERR

          onInstallFail() {
            open "$VNC_URL"
            fg
          }

          function vncdo {
            echo Sending VNC inputs for "$1"
            ${timeout} 15s vncdo -p "$VNC_PASSWORD" -s "$VNC_ADDRESS::$VNC_PORT" capture "$TART_HOME/vms/darwin-vm/$(date +%F_%H-%M-%S).png" "''${@:2}"
          }

          sleep 60
          vncdo "Getting Started" key space

          sleep 30
          vncdo "Language" key enter

          sleep 30
          vncdo "Select Your Country or Region" type australia pause 0.3 key shift-tab pause 0.3 key space

          sleep 10
          vncdo "Written and Spoken Languages" key shift-tab pause 0.3 key space

          sleep 10
          vncdo "Accessibility" key shift-tab pause 0.3 key space

          sleep 10
          vncdo "Data & Privacy" key shift-tab pause 0.3 key space

          sleep 10
          vncdo "Migration Assistant" key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key space

          sleep 10
          vncdo "Sign in with Your Apple ID" key shift-tab pause 0.3 key shift-tab pause 0.3 key space

          sleep 10
          vncdo "Are you sure you want to skip signing in with an Apple ID?" key tab pause 0.3 key space

          sleep 10
          vncdo "Terms and Conditions" key shift-tab pause 0.3 key space

          sleep 10
          vncdo "I have read and agree to the macOS Software License Agreement." key tab pause 0.3 key space

          sleep 10
          vncdo "Create a Computer Account" type "${user.name}" pause 0.3 key tab pause 0.3 type "${username}" pause 0.3 key tab pause 0.3 type "$VM_PASS" pause 0.3 key tab pause 0.3 type "$VM_PASS" pause 0.3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key space

          sleep 10
          vncdo "Enable Location Services" key shift-tab pause 0.3 key space

          sleep 10
          vncdo "Are you sure you don't want to use Location Services?" key tab pause 0.3 key space

          sleep 10
          vncdo "Select Your Time Zone" key tab pause 0.3 type UTC pause 0.3 key enter pause 0.3 key shift-tab pause 0.3 key space

          sleep 10
          vncdo "Analytics" key tab pause 0.3 key space pause 0.3 key shift-tab pause 0.3 key space

          sleep 10
          vncdo "Screen Time" key tab pause 0.3 key space

          sleep 10
          vncdo "Siri" key tab pause 0.3 key space pause 0.3 key shift-tab pause 0.3 key space

          sleep 10
          vncdo "Choose Your Look" key shift-tab pause 0.3 key space

          sleep 10

          # macOS installation possibly complete
          echo macos-possibly-finished > "$STATE_FILE"

          vncdo "enabling Voice Over" key alt-f5 pause 5 key v

          vncdo "opening System Settings" move 0 0 click 1 pause 0.3 key down key down key enter

          sleep 10
          vncdo "navigating to Sharing" key up pause 3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key space

          sleep 10
          vncdo "enabling Screen Sharing" key tab pause 0.3 key tab pause 0.3 key space

          sleep 10
          vncdo "enabling Remote Login" key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key tab pause 0.3 key space

          vncdo "enabling Full Disk Access" key tab key space pause 10 key tab key space pause 1 key shift-tab key shift-tab key space

          vncdo "disabling Voice Over" key alt-f5

          # Installation complete, tart/AV private VNC server no longer necessary
          rm "$TART_HOME/tart.out"

          VM_IP=$(tart ip darwin-vm)
          export VM_IP

          if [[ -f $TART_HOME/id_ed25519 ]]; then
            rm "$TART_HOME/id_ed25519" "$TART_HOME/id_ed25519.pub"
          fi

          ssh-keygen -t ed25519 -f "$TART_HOME/id_ed25519" -N ""

          # Sometimes it takes time for this to succeed after enabling SSH
          retry -d 5 -t 10 ${lib.getExe (pkgs.writeShellApplication {
            name = "ssh-keyscan-vm";
            text = ''
              set -x

              ssh-keyscan -t ed25519 "$VM_IP" | tee "$TART_HOME/known_hosts"

              if [[ ! -s $TART_HOME/known_hosts ]]; then
                exit 1
              fi
            '';
          })}

          # Use SSH keys
          passh -p "$VM_PASS" ssh-copy-id ${sshDestination}

          if [[ $(ssh ${sshDestination} "echo yo") == "yo" ]]; then
            echo macos-installed > "$STATE_FILE"
          else
            echo "error: couldn't SSH into VM"
            echo "press Ctrl-C to close the VM, then rerun the script"
            exit 1
          fi

          # Enable passwordless sudo
          passh -p "$VM_PASS" ssh ${sshDestination} "sudo -S sh -c \"mkdir -p /etc/sudoers.d/; echo '%admin ALL=(ALL) NOPASSWD: ALL' | VISUAL=tee visudo /etc/sudoers.d/admin-nopasswd\""

          # Install Nix
          scp ${sshOptions} ${lib.getExe nix-installer} "${username}@$VM_IP:/tmp/nix-installer"

          ssh ${sshDestination} /tmp/nix-installer install --no-confirm

          ssh ${sshDestination} "sudo cp /etc/nix/nix.conf /etc/nix/nix.conf.bak"

          # Necessary for nix-copy-closure
          echo "trusted-users = ${username}" | ssh ${sshDestination} "sudo tee -a /etc/nix/nix.conf"

          ssh ${sshDestination} "sudo launchctl kickstart -k system/org.nixos.nix-daemon"

          NIX_SSHOPTS="${sshOptions}" nix-copy-closure --to "${username}@$VM_IP" ${config.system.build.toplevel}

          # Restore the version without `trusted-users` to match known SHA256 hashes
          ssh ${sshDestination} "sudo mv /etc/nix/nix.conf.bak /etc/nix/nix.conf"

          ssh ${sshDestination} "${config.system.build.toplevel}/sw/bin/darwin-rebuild activate"

          if [[ $(ssh ${sshDestination} "realpath /run/current-system") == ${config.system.build.toplevel} ]]; then
            echo installation-complete > "$STATE_FILE"
          else
            echo "error: nix-darwin installation did not complete successfully"
            echo "press Ctrl-C to close the VM, then rerun the script"
            exit 1
          fi

          ${timeout} 30s ssh ${sshDestination} "sudo bash -c 'rm /etc/sudoers.d/admin-nopasswd ~/.ssh/authorized_keys; shutdown -h now'" || true

          sleep 30

          VM_RUNNING=$(tart list --format json | jq '.[] | select(.Name == "darwin-vm") | .Running')

          if [[ "$VM_RUNNING" == "true" ]]; then
            echo shutdown-failed > "$STATE_FILE"
            echo "error: failed to shut down VM"
            echo "forcibly stopping VM, please rerun the script"
            tart stop --timeout 5 darwin-vm
            exit 1
          fi
        fi

        # Remove trap now that installation has finished
        trap - ERR

        tart run darwin-vm
      '';
    }) // {
      postBuild = ''
        ln -s ${config.system.build.toplevel} $out/system
      '';
    };
  };
}
