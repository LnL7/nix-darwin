{ config, pkgs, ... }:

{
  system.activationScripts.preUserActivation.text = "echo hook preUserActivation";
  system.activationScripts.extraUserActivation.text = "echo hook extraUserActivation";
  system.activationScripts.postUserActivation.text = "echo hook postUserActivation";

  system.activationScripts.preActivation.text = "echo hook preActivation";
  system.activationScripts.extraActivation.text = "echo hook extraActivation";
  system.activationScripts.postActivation.text = "echo hook postActivation";

  test = ''
    countHooks() {
      awk '/echo hook / {i++ ; print i " => " $0}' "$2" | grep "$1"
    }

    echo checking activation hooks in /activate-user >&2
    countHooks "1 => echo hook preUserActivation" ${config.out}/activate-user
    countHooks "2 => echo hook extraUserActivation" ${config.out}/activate-user
    countHooks "3 => echo hook postUserActivation" ${config.out}/activate-user

    echo checking activation hooks in /activate >&2
    countHooks "1 => echo hook preActivation" ${config.out}/activate
    countHooks "2 => echo hook extraActivation" ${config.out}/activate
    countHooks "3 => echo hook postActivation" ${config.out}/activate
  '';
}
