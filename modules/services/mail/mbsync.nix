{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.mbsync;

  mbsyncOptions = [ "--all" ] ++ optional (cfg.verbose) "--verbose"
                  ++ optional (cfg.configFile != "")
                    "--config ${cfg.configFile}";

in {

  options.services.mbsync = {
    enable = mkEnableOption "mbsync";

    package = mkOption {
      type = types.package;
      default = pkgs.isync;
      defaultText = literalExample "pkgs.isync";
      example = literalExample "pkgs.isync";
      description = "The package to use for the mbsync binary.";
    };

    startInterval = mkOption {
      type = types.nullOr types.int;
      default = 300;
      example = literalExample "300";
      description = "Optional key to run mbsync every N seconds";
    };

    verbose = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether mbsync should produce verbose output.
      '';
    };

    configFile = mkOption {
      type = types.str;
      default = "";
      description = ''
        Optional configuration file to link to use instead of
        the default file (<filename>~/.mbsyncrc</filename>).
      '';
    };

    postExec = mkOption {
      type = types.str;
      default = "";
      example = "\${pkgs.mu}/bin/mu index";
      description = ''
        An optional command to run after mbsync executes successfully.
        This is useful for running mailbox indexing tools.
      '';
    };
  };

  config = mkIf cfg.enable {

    launchd.user.agents.mbsync = {
      script = ''
        ${cfg.package}/bin/mbsync ${concatStringsSep " " mbsyncOptions}
        ${optionalString (cfg.postExec != "") cfg.postExec}
      '';

      serviceConfig.KeepAlive     = false;
      serviceConfig.RunAtLoad     = true;
      serviceConfig.StartInterval = cfg.startInterval;
    };
  };
}
