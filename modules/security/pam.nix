{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.security.pam;
  touchIdAuth = ''
    sudo_file=/etc/pam.d/sudo
    sudo_local_file=/etc/pam.d/sudo_local
    tid_file=/etc/pam.d/nix-darwin-touchIdAuth
    del_tid() {
      local first=1
      local f
      for f; do
        if [[ ! -e $f ]]; then
          continue
        fi
        if [[ -n $first ]]; then
          first=""
          set --
        fi
        set -- "$@" "$f"
      done
      if [[ $# != 0 ]]; then
        ${pkgs.gawk}/bin/awk -i inplace '
          /^[[:space:]]*#/ || !NF {
            print
            next
          }
          !($1 == "auth" && $3 ~ /(\/|^)pam_(tid|reattach)\.so$/) {
            print
          }
        ' "$@"
      fi
    }
    ensure_include() {
      local f="$1"
      local inc="$2"
      local found=""
      if [[ -e $f ]]; then
        found=$(${pkgs.gawk}/bin/awk -v inc="$inc" '!/^[[:space:]]*#/ && NF {
          if ($1 == "auth" && $2 == "include" && $3 == inc) {
            print 1
            exit
          }
        }' "$f")
      fi
      if [[ -z $found ]]; then
        add_at_top "$f" "auth       include        $inc"
      fi
    }
    add_at_top() {
      local f="$1"
      local s="$2"
      if [[ -s $f ]]; then
        ${pkgs.gawk}/bin/awk -i inplace -v s="$s" '
          BEGINFILE { print s }
          { print }
        ' "$f"
      else
        echo "$s" >"$f"
      fi
    }
    ensure_content() {
      local f="$1"
      local content="$(cat)"
      if [[ ! -e $f ]] || [[ "$(< "$f")" != "$content" ]]; then
        echo "$content" >"$f"
      fi
    }

    # sudo settings
    del_tid "$sudo_file" "$sudo_local_file"
    ensure_include "$sudo_file" $(basename "$sudo_local_file")
    ensure_include "$sudo_local_file" $(basename "$tid_file")
    ensure_content "$tid_file" <<'EOF'
    ${optionalString
      (cfg.touchIdAuth.enable && cfg.touchIdAuth.reattach.enable)
      ("auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so"
        + optionalString cfg.touchIdAuth.reattach.ignoreSSH " ignore_ssh"
      )
    }
    ${optionalString
      cfg.touchIdAuth.enable
      "auth       sufficient     pam_tid.so"
    }
    EOF
  '';
in
{
  options.security.pam = {
    touchIdAuth.enable = mkEnableOption (lib.mdDoc ''
      sudo authentication with Touch ID

      When enabled, this option adds the following line to /etc/pam.d/sudo_local:

          auth       sufficient     pam_tid.so

      (Note that macOS before Sonoma resets this file when doing a system update. As such, sudo
        authentication with Touch ID won't work after a system update until the nix-darwin
        configuration is reapplied.)
    '');
    touchIdAuth.reattach.enable = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Enable re-attaching a program to the user's bootstrap session.

        This allows programs like tmux and screen that run in the background to
        survive across user sessions to work with PAM services that are tied to the
        bootstrap session.

        When enabled, this option adds the following line before the pam_tid.so line:

            auth       optional       /path/in/nix/store/lib/pam/pam_reattach.so [options]..."
      '';
    };
    touchIdAuth.reattach.ignoreSSH = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Enable the ignore_ssh option for pam_reattach.so
      '';
    };
  };
  config = {
    system.activationScripts.pam.text = ''
      # PAM settings
      echo >&2 "setting up pam..."
      (
        set -euo pipefail
        ${touchIdAuth}
      ) || exit 1
    '';
  };
}
