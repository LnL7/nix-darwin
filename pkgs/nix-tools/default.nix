{ lib
, coreutils
, jq
, git
, substituteAll
, stdenv
, profile ? "/nix/var/nix/profiles/system"
, nixPackage ? "/nix/var/nix/profiles/default"
, systemPath ? "$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
}:

let
  extraPath = lib.makeBinPath [ nixPackage coreutils jq git ];

  writeProgram = name: env: src:
    substituteAll ({
      inherit name src;
      dir = "bin";
      isExecutable = true;
    } // env);

  path = "${extraPath}:${systemPath}";
in
{
  darwin-option = writeProgram "darwin-option"
    {
      inherit path;
      inherit (stdenv) shell;
    }
    ./darwin-option.sh;

  darwin-rebuild = writeProgram "darwin-rebuild"
    {
      inherit path profile;
      inherit (stdenv) shell;
    }
    ./darwin-rebuild.sh;

  darwin-version = writeProgram "darwin-version"
    {
      inherit (stdenv) shell;
      path = lib.makeBinPath [ jq ];
    }
    ./darwin-version.sh;
}
