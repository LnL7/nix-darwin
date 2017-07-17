{ config, lib, pkgs, ... }:

with lib;

let
  environment = concatStringsSep " "
    [ "TMPDIR=/build/tmp"
      "NIX_REMOTE=daemon"
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
in

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ pkgs.nix-repl
    ];

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;
  programs.bash.enableCompletion = false;

  # Recreate /run/current-system symlink after boot.
  services.activate-system.enable = true;

  services.nix-daemon.enable = true;

  nix.binaryCaches = [ http://cache1 ];
  nix.binaryCachePublicKeys = [ "cache.daiderd.com-1:R8KOWZ8lDaLojqD+v9dzXAqGn29gEzPTTbr/GIpCTrI=" ];

  nix.trustedUsers = [ "@admin" "@hydra" ];

  nix.extraOptions = ''
    pre-build-hook =
  '';

  nix.gc.automatic = true;
  nix.gc.options = "--max-freed $((25 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";

  environment.etc."per-user/hydra/ssh/authorized_keys".text = concatStringsSep "\n"
    [ "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --write\" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCVsc0pHGsskoayziMhA2e59bHPWe0bbKgusmqhuJFBGQ1BAk9UmPzKCWE3nCiV6CLD1+SygVkBjb06DYtc+94BnzviCa9qZtL0G4+2vhp6x8OvXh8xlf/eWw3k5MWlvu+kjJFpbW8wHWTiUqzH+uEeHklAosT0lFNjiIYd/Vs3JAezhUR62a6c7ZjWOd5F7ALGEKzOiwC4i37kSgGsIWNCbe0Ku7gyr718zhMGeyxax6saHhnkSpIB+7d6oHhKeiJSFMWctNmz1/qxXUPbxNaJvqgdKlVHhN+B7x/TIbkVr5pTC59Okx9LTcpflFIv79VT+Gf1K7VypZpSvJjG0xFRt8iDs1+ssWFBfvpo94vUbZ+ZwMDcBGR5iJeO41Gj5fYn5aaDl32RXfJ9Fkwael1L6pcXtkIc66jk+KQQpgoeNj8Y3Emntpqva/2AM41wDDvr5tKp5KhEKFLM95CoiWq+g88pZLcpqLK7wooDVqNkVUEbMaj9lBN0AzU9mcsIRGvTa6CmWAdBvwqS2fRZD97Oarqct9AWgb0X6mOUq9BJNi4i4xvjgnVkylLwtLUnibR/PeXMtkb9bv6BEZXNf5ACqxSjKXJyaIHI65I5TILCr5eEgaujgvmkREn6U3T1NZAUIeVe9aVYLqehYh79OHUBzggoHqidRrXBB/6zdg9UgQ=="
      "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --write\" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCnubA1pRqlpoAXkZ1q5nwhqi1RY2z840wFLFDj7vAMSups9E2U8PNIVtuVYApZpkBWIpzD4GGbQTF5Itnu5uBpJswc2Yat9yGWO/guuVyXIaRoBIM0Pg1WBWcWsz+k4rNludu9UQ74FHqEiqZIuIuOcgV+RIZn8xQlGt2kUqN9TWboHhZz8Zhx7EtGSJH6MJRLn3mA/pPjOF6k1jiiFG1pVDuqBTZPANkelWYCWAJ46jCyhxXltWE/jkBYGc/XbB8yT7DFE1XC6TVsSEp68R9PhVG3yqxqY06sniEyduSoGt/TDr6ycERd93bvLElXFATes85YiFszeaUgayYSKwQPe0q7YeHMhIXL0UYJYaKVVgT9saFDiHDzde7kKe+NA+J4+TbIk7Y/Ywn0jepsYV13M7TyEqgqbu9fvVGF3JI9+4g0m1gAzHTa7n6iiAedtz+Pi79uCEpRD2hWSSoLWroyPlep8j1p2tygtFsrieePEukesoToCTwqg1Ejnjh+yKdtUbc6xpyRvl3hKeO8QbCpfaaVd27e4vE4lP2JMW6nOo8b0wlVXQIFe5K2zh52q1MSwhLAq6Kg8oPmgj0lru4IivmPc+/NVwd3Qj3E9ZB8LRfTesfbcxHrC8lF5dL/QpLMeLwebrwCxL19gI0kxmDIaUQuHSyP3B2z+EmBKcN/Xw=="
    ];

  system.activationScripts.extraActivation.text = ''
    set +e
    printf "checking for hydra group... "
    dscl . -read /Groups/hydra &> /dev/null
    case $? in
      0) echo "yes" ;;
      56)
        echo "no, created"
        dseditgroup -o create -r "Hydra group" -i 122 hydra >&2 || exit
        ;;
    esac

    printf "checking for hydra user... "
    id hydra &> /dev/null
    case $? in
      0) echo "yes" ;;
      1)
        echo "no, created"
        sysadminctl -addUser hydra -fullName "Hydra" -UID 122 >&2 || exit
        dscl . -create /Users/hydra IsHidden 1 || exit
        ;;
    esac

    printf "checking group of hydra user... "
    if test "$(id -g hydra 2> /dev/null)" -eq 122; then
      echo "ok"
    else
      echo "no, updated"
      dseditgroup -o edit -t user -a hydra hydra
      dscl . -create /Users/hydra PrimaryGroupID 122 >&2 || exit
    fi
    set -e

    printf "configuring ssh keys for hydra... "
    mkdir -p ~hydra/.ssh
    cp -f /etc/per-user/hydra/ssh/authorized_keys ~hydra/.ssh/authorized_keys
    chown hydra:hydra ~hydra/.ssh ~hydra/.ssh/authorized_keys
    echo "ok"

    mkdir -m 1777 -p /build/tmp
  '';
}
