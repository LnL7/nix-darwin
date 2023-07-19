{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.karabiner-elements;

  parentAppDir = "/Applications/.Nix-Karabiner";
in

{
  options = {
    services.karabiner-elements.enable = mkEnableOption (lib.mdDoc "Karabiner-Elements");
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.karabiner-elements ];

    system.activationScripts.preActivation.text = ''
      rm -rf ${parentAppDir}
      mkdir -p ${parentAppDir}
      # Kernel extensions must reside inside of /Applications, they cannot be symlinks
      cp -r ${pkgs.karabiner-elements.driver}/Applications/.Karabiner-VirtualHIDDevice-Manager.app ${parentAppDir}
    '';

    system.activationScripts.postActivation.text = ''
      echo "attempt to activate karabiner system extension and start daemons" >&2
      launchctl unload /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist
      launchctl load -w /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist
    '';

    # We need the karabiner_grabber and karabiner_observer daemons to run after the
    # Nix Store has been mounted, but we can't use wait4path as they need to be
    # executed directly for the Input Monitoring permission. We also want these
    # daemons to auto restart but if they start up without the Nix Store they will
    # refuse to run again until they've been unloaded and loaded back in so we can
    # use a helper daemon to start them. We also only want to run the daemons after
    # the system extension is activated, so we can call activate from the manager
    # which will block until the system extension is activated.
    launchd.daemons.start_karabiner_daemons = {
      serviceConfig.ProgramArguments = [
        "/bin/sh" "-c"
        "/bin/wait4path /nix/store &amp;&amp; ${pkgs.writeScript "start_karabiner_daemons" ''
          ${parentAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
          launchctl kickstart system/org.pqrs.karabiner.karabiner_grabber
          launchctl kickstart system/org.pqrs.karabiner.karabiner_observer
        ''}"
      ];
      serviceConfig.Label = "org.nixos.start_karabiner_daemons";
      serviceConfig.RunAtLoad = true;
    };

    launchd.daemons.karabiner_grabber = {
      serviceConfig.ProgramArguments = [
        "${pkgs.karabiner-elements}/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_grabber"
      ];
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.Label = "org.pqrs.karabiner.karabiner_grabber";
      serviceConfig.KeepAlive.SuccessfulExit = true;
      serviceConfig.KeepAlive.Crashed = true;
      serviceConfig.KeepAlive.AfterInitialDemand = true;
    };

    launchd.daemons.karabiner_observer = {
      serviceConfig.ProgramArguments = [
        "${pkgs.karabiner-elements}/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_observer"
      ];

      serviceConfig.Label = "org.pqrs.karabiner.karabiner_observer";
      serviceConfig.KeepAlive.SuccessfulExit = true;
      serviceConfig.KeepAlive.Crashed = true;
      serviceConfig.KeepAlive.AfterInitialDemand = true;
    };

    launchd.daemons.Karabiner-DriverKit-VirtualHIDDeviceClient = {
      serviceConfig.ProgramArguments = [
        "/bin/sh" "-c"
        # For unknown reasons this daemon will fail if VirtualHIDDeviceClient is not exec'd.
        "/bin/wait4path /nix/store &amp;&amp; exec \"${pkgs.karabiner-elements.driver}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-DriverKit-VirtualHIDDeviceClient.app/Contents/MacOS/Karabiner-DriverKit-VirtualHIDDeviceClient\""
      ];
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.Label = "org.pqrs.Karabiner-DriverKit-VirtualHIDDeviceClient";
      serviceConfig.KeepAlive = true;
    };

    # Normally karabiner_console_user_server calls activate on the manager but
    # because we use a custom location we need to call activate manually.
    launchd.user.agents.activate_karabiner_system_ext = {
      serviceConfig.ProgramArguments = [
        "${parentAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" "activate"
      ];
      serviceConfig.RunAtLoad = true;
    };

    # We need this to run every reboot as /run gets nuked so we can't put this
    # inside the preActivation script as it only gets run on darwin-rebuild switch.
    launchd.daemons.setsuid_karabiner_session_monitor = {
      serviceConfig.ProgramArguments = [
        "/bin/sh" "-c"
        "/bin/wait4path /nix/store &amp;&amp; ${pkgs.writeScript "setsuid_karabiner_session_monitor" ''
          rm -rf /run/wrappers
          mkdir -p /run/wrappers/bin
          install -m4555 "${pkgs.karabiner-elements}/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_session_monitor" /run/wrappers/bin
        ''}"
      ];
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive.SuccessfulExit = false;
    };

    launchd.user.agents.karabiner_session_monitor = {
      serviceConfig.ProgramArguments = [
        "/bin/sh" "-c"
        "/bin/wait4path /run/wrappers/bin &amp;&amp; /run/wrappers/bin/karabiner_session_monitor"
      ];
      serviceConfig.Label = "org.pqrs.karabiner.karabiner_session_monitor";
      serviceConfig.KeepAlive = true;
    };

    environment.userLaunchAgents."org.pqrs.karabiner.agent.karabiner_grabber.plist".source = "${pkgs.karabiner-elements}/Library/LaunchAgents/org.pqrs.karabiner.agent.karabiner_grabber.plist";
    environment.userLaunchAgents."org.pqrs.karabiner.agent.karabiner_observer.plist".source = "${pkgs.karabiner-elements}/Library/LaunchAgents/org.pqrs.karabiner.agent.karabiner_observer.plist";
    environment.userLaunchAgents."org.pqrs.karabiner.karabiner_console_user_server.plist".source = "${pkgs.karabiner-elements}/Library/LaunchAgents/org.pqrs.karabiner.karabiner_console_user_server.plist";
  };
}
