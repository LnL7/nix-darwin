{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.timemachine.AutoBackup = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
       Enable or disable automatic backup. Defaults to no automatic backup (false). 
      '';
    };

    system.defaults.timemachine.SkipSystemFiles = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
       Wether to skip system files when backing up. Defaults to not skipping (false). 
      '';
    };


    system.defaults.timemachine.SkipPaths = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      example = literalExample '' 
        [
          "~user/Music"
          "~user/Downloads"
        ]
      '';
      description = ''
        Set the paths to exclude from the backup. Default: do not exclude anything (null).
      '';
    };

  };
}
