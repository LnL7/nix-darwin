{ config, pkgs, ... }:

let
  lorri = pkgs.runCommand "lorri-0.0.0" {} "mkdir $out";
  plistPath = "${config.out}/user/Library/LaunchAgents/org.nixos.lorri.plist";
  actual = pkgs.runCommand "convert-plist-to-json" { buildInputs = [ pkgs.xcbuild ]; }
    "plutil -convert json -o $out ${plistPath}";
  actualJson = builtins.fromJSON (builtins.readFile "${actual.out}");
  expectedJson = builtins.fromJSON ''
  {
    "EnvironmentVariables": {
            "NIX_PATH": "${"nixpkgs="+ toString pkgs.path}",
            "PATH": "${builtins.unsafeDiscardStringContext pkgs.nix}/bin"
    },
    "KeepAlive": true,
    "Label": "org.nixos.lorri",
    "ProcessType": "Background",
    "ProgramArguments": [
            "/bin/sh",
            "-c",
            "exec ${builtins.unsafeDiscardStringContext pkgs.lorri}/bin/lorri daemon"
    ],
    "RunAtLoad": true
  }
  '';
  testResult = toString (actualJson == expectedJson);
in
{
  services.lorri.enable = true;
  test = ''
    ${pkgs.xcbuild}/bin/plutil -lint ${plistPath}
    [ ${testResult} ];
  '';
}

