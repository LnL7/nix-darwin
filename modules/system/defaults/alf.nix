{ config, lib, ... }:

with lib;

{
  options = {
    system.defaults.alf.globalstate = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        # Apple menu > System Preferences > Security and Privacy > Firewall
        Enable the internal firewall to prevent unauthorised applications, programs
        and services from accepting incoming connections.

        0 = disabled
        1 = enabled
        2 = blocks all connections except for essential services
      '';
    };

    system.defaults.alf.allowsignedenabled = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        # Apple menu > System Preferences > Security and Privacy > Firewall
        Allows any signed Application to accept incoming requests. Default is true.

        0 = disabled
        1 = enabled
      '';
    };

    system.defaults.alf.allowdownloadsignedenabled = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        # Apple menu > System Preferences > Security and Privacy > Firewall
        Allows any downloaded Application that has been signed to accept incoming requests. Default is 0.

        0 = disabled
        1 = enabled
      '';
    };

    system.defaults.alf.loggingenabled = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        # Apple menu > System Preferences > Security and Privacy > Firewall
        Enable logging of requests made to the firewall. Default is 0.

        0 = disabled
        1 = enabled
      '';
    };

    system.defaults.alf.stealthenabled = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        # Apple menu > System Preferences > Security and firewall
        Drops incoming requests via ICMP such as ping requests. Default is 0.

        0 = disabled
        1 = enabled
      '';
    };
  };
}
