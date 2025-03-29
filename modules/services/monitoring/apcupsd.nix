# Taken from NixOS/nixpkgs and adapted to use of nix-darwin:
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/monitoring/apcupsd.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.apcupsd;

  configFile = pkgs.writeText "apcupsd.conf" ''
    ## apcupsd.conf v1.1 ##
    # apcupsd complains if the first line is not like above.
    ${cfg.configText}
    SCRIPTDIR ${toString scriptDir}
  '';

  # List of events from "man apccontrol"
  eventList = [
    "annoyme"
    "battattach"
    "battdetach"
    "changeme"
    "commfailure"
    "commok"
    "doreboot"
    "doshutdown"
    "emergency"
    "failing"
    "killpower"
    "loadlimit"
    "mainsback"
    "onbattery"
    "offbattery"
    "powerout"
    "remotedown"
    "runlimit"
    "timeout"
    "startselftest"
    "endselftest"
  ];

  shellCmdsForEventScript = eventname: commands: ''
    echo "#!${pkgs.runtimeShell}" > "$out/${eventname}"
    echo '${commands}' >> "$out/${eventname}"
    chmod a+x "$out/${eventname}"
  '';

  eventToShellCmds = event: if builtins.hasAttr event cfg.hooks then (shellCmdsForEventScript event (builtins.getAttr event cfg.hooks)) else "";

  scriptDir = pkgs.runCommand "apcupsd-scriptdir" { preferLocalBuild = true; } (''
    mkdir "$out"
    # Copy SCRIPTDIR from apcupsd package
    cp -r ${cfg.package}/etc/apcupsd/* "$out"/
    # Make the files writeable (nix will unset the write bits afterwards)
    chmod u+w "$out"/*
    # Remove the sample event notification scripts, because they don't work
    # anyways (they try to send mail to "root" with the "mail" command)
    (cd "$out" && rm changeme commok commfailure onbattery offbattery)
    # Remove the sample apcupsd.conf file (we're generating our own)
    rm "$out/apcupsd.conf"
    # Set the SCRIPTDIR= line in apccontrol to the dir we're creating now
    sed -i -e "s|^SCRIPTDIR=.*|SCRIPTDIR=$out|" "$out/apccontrol"
    '' + lib.concatStringsSep "\n" (map eventToShellCmds eventList)

  );

  # Ensure the CLI uses our generated configFile
  wrappedBinaries = pkgs.runCommand "apcupsd-wrapped-binaries" {
    preferLocalBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
      for p in "${lib.getBin cfg.package}/bin/"*; do
          bname=$(basename "$p")
          makeWrapper "$p" "$out/bin/$bname" --add-flags "-f ${configFile}"
      done
    '';

  apcupsdWrapped = pkgs.symlinkJoin {
    name = "apcupsd-wrapped";
    # Put wrappers first so they "win"
    paths = [ wrappedBinaries cfg.package ];
  };
in

{

  ###### interface

  options = {

    services.apcupsd = {

      enable = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = ''
          Whether to enable the APC UPS daemon. apcupsd monitors your UPS and
          permits orderly shutdown of your computer in the event of a power
          failure. User manual: http://www.apcupsd.com/manual/manual.html.
          Note that apcupsd runs as root (to allow shutdown of computer).
          You can check the status of your UPS with the "apcaccess" command.
        '';
      };

      package = lib.mkOption {
        default = pkgs.apcupsd;
        type = lib.types.package;
        description = ''
          The apcupsd package to use.
        '';
      };

      configText = lib.mkOption {
        default = ''
          UPSTYPE usb
          NISIP 127.0.0.1
          BATTERYLEVEL 50
          MINUTES 5
          # Required on darwin
          LOCKFILE /run
        '';
        type = lib.types.lines;
        description = ''
          Contents of the runtime configuration file, apcupsd.conf. The default
          settings makes apcupsd autodetect USB UPSes, limit network access to
          localhost and shutdown the system when the battery level is below 50
          percent, or when the UPS has calculated that it has 5 minutes or less
          of remaining power-on time. See man apcupsd.conf for details.
        '';
      };

      hooks = lib.mkOption {
        default = {};
        example = {
          doshutdown = "# shell commands to notify that the computer is shutting down";
        };
        type = lib.types.attrsOf lib.types.lines;
        description = ''
          Each attribute in this option names an apcupsd event and the string
          value it contains will be executed in a shell, in response to that
          event (prior to the default action). See "man apccontrol" for the
          list of events and what they represent.

          A hook script can stop apccontrol from doing its default action by
          exiting with value 99. Do not do this unless you know what you're
          doing.
        '';
      };

    };

  };


  ###### implementation

  config = lib.mkIf cfg.enable {

    assertions = [ {
      assertion = let hooknames = builtins.attrNames cfg.hooks; in lib.all (x: lib.elem x eventList) hooknames;
      message = ''
        One (or more) attribute names in services.apcupsd.hooks are invalid.
        Current attribute names: ${toString (builtins.attrNames cfg.hooks)}
        Valid attribute names  : ${toString eventList}
      '';
    } ];

    # Give users access to the "apcaccess" tool
    environment.systemPackages = [ apcupsdWrapped ];

    # NOTE 1: apcupsd runs as root because it needs permission to run
    # "shutdown"
    #
    # NOTE 2: When apcupsd calls "wall", it prints an error because stdout is
    # not connected to a tty (it is connected to the journal):
    #   wall: cannot get tty name: Inappropriate ioctl for device
    # The message still gets through.
    # TODO: Maybe create /run/apcupsd before running, would need to generate
    #       some kind of wrapper script then.
    launchd.daemons.apcupsd = {
      serviceConfig = {
        ProgramArguments = [
          "${cfg.package}/bin/apcupsd"
          "-b"
          "-f"
          "${configFile}"
          "-d1"
        ];
        KeepAlive = true;
        RunAtLoad = true;
      };
    };

  };

}
