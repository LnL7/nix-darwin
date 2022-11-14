{ config, pkgs, ... }:

{
  system.defaults.screencapture.location = "/tmp/not-so-random/nested/directory/directory";
  system.screencapture.createLocation = true;

  test = ''
    echo checking creation of screencapture location >&2
    grep "mkdir -pv \"${config.system.defaults.screencapture.location}\"" ${config.out}/activate-user
  '';
}
