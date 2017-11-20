{ config, lib, pkgs, ... }:

with lib;

let
usersWithSymlinks = attrValues (flip filterAttrs config.users.users (n: u:
      u.symlinks != {}
));

activationScriptForUser = user: flip mapAttrsToList user.symlinks (reltarget: src:
  "update_symlink \"${src}\" \"${user.home}/${reltarget}\""
);

activationScript = ''
    ${builtins.readFile ./update-symlinks.sh}
    ${concatStringsSep "\n" (flatten (map activationScriptForUser usersWithSymlinks))}
'';

in {
  ###### interface

  options = {

    users.users = mkOption {
      options = [{
        symlinks = mkOption {
          default = {};
          description = ''
            An attrset of relative paths and targets to symlink in to
            the user's HOME.
          '';
        };
      }];
    };
  };

  ###### implementation

  config = {
    system.activationScripts.usersymlinks.text = activationScript;
  } // (mkIf (builtins.currentSystem == "x86_64-darwin") {
    system.activationScripts.extraActivation.text = activationScript;
  });

}
