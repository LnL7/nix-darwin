{ lib
, coreutils
, jq
, git
, substituteAll
, stdenv
, profile ? "/nix/var/nix/profiles/system"
, # This should be kept in sync with the default
  # `environment.systemPath`. We err on side of including conditional
  # things like the profile directories, since they’re more likely to
  # help than hurt, and this default is mostly used for fresh
  # installations anyway.
  systemPath ? lib.concatStringsSep ":" [
  "$HOME/.nix-profile/bin"
  "/etc/profiles/per-user/$USER/bin"
  "/run/current-system/sw/bin"
  "/nix/var/nix/profiles/default/bin"
  "/usr/local/bin"
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
]
, nixPackage ? null
, # This should be kept in sync with the default `nix.nixPath`.
  nixPath ? lib.concatStringsSep ":" [
  "darwin-config=/etc/nix-darwin/configuration.nix"
  "/nix/var/nix/profiles/per-user/root/channels"
]
}:

let
  extraPath = lib.makeBinPath [ coreutils jq git nixPackage ];

  writeProgram = name: env: src:
    substituteAll ({
      inherit name src;
      dir = "bin";
      isExecutable = true;
      meta.mainProgram = name;
    } // env);

  path = "${extraPath}:${systemPath}";
in
{
  darwin-option = writeProgram "darwin-option"
    {
      inherit path nixPath;
      inherit (stdenv) shell;
    }
    ./darwin-option.sh;

  darwin-rebuild = writeProgram "darwin-rebuild"
    {
      inherit path nixPath profile;
      inherit (stdenv) shell;
      postInstall = ''
        mkdir -p $out/share/zsh/site-functions
        cp ${./darwin-rebuild.zsh-completions} $out/share/zsh/site-functions/_darwin-rebuild
      '';
    }
    ./darwin-rebuild.sh;

  darwin-version = writeProgram "darwin-version"
    {
      inherit (stdenv) shell;
      path = lib.makeBinPath [ jq ];
    }
    ./darwin-version.sh;
}
