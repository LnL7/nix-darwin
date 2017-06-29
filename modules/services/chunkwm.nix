{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.chunkwm;

in

{
  options = {
    services.chunkwm.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the chunkwm window manager.";
    };

    services.chunkwm.package = mkOption {
      type = types.package;
      default = pkgs.chunkwm-core;
      defaultText = "pkgs.chunkwm-core";
      description = "This option specifies the chunkwm package to use";
    };

    services.chunkwm.hotload = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable hotload";
    };

    services.chunkwm.port = mkOption {
      type = types.int;
      default = 3920;
      description = "ChunkC port";
    };

    services.chunkwm.plugins.dir = mkOption {
      type = types.path;
      default = "/run/current-system/sw/lib/chunkwm/plugins";
      description = "Chunkwm Plugins directory";
    };

    services.chunkwm.plugins.list = mkOption {
      type = types.listOf (types.enum [ "border" "tiling" "ffm" ]);
      default = [ "border" "tiling" "ffm" ];
      description = "Chunkwm Plugins to enable";
    };

    services.chunkwm.plugins.tiling.config = mkOption {
      type = types.lines;
      default = ''
      #!/bin/bash

      # use 'chunkc' to send message to socket
      export CHUNKC_SOCKET=4131

      chunkc config global_desktop_mode           bsp
      chunkc config 2_desktop_mode                monocle
      chunkc config 5_desktop_mode                float

      chunkc config 1_desktop_tree                ~/.chunkwm_layouts/dev_1

      chunkc config global_desktop_offset_top     25
      chunkc config global_desktop_offset_bottom  15
      chunkc config global_desktop_offset_left    15
      chunkc config global_desktop_offset_right   15
      chunkc config global_desktop_offset_gap     15

      chunkc config 1_desktop_offset_top          25
      chunkc config 1_desktop_offset_bottom       15
      chunkc config 1_desktop_offset_left         15
      chunkc config 1_desktop_offset_right        15
      chunkc config 1_desktop_offset_gap          15

      chunkc config 3_desktop_offset_top          25
      chunkc config 3_desktop_offset_bottom       15
      chunkc config 3_desktop_offset_left         15
      chunkc config 3_desktop_offset_right        15

      chunkc config desktop_padding_step_size     10.0
      chunkc config desktop_gap_step_size         5.0

      chunkc config bsp_spawn_left                1
      chunkc config bsp_optimal_ratio             1.618
      chunkc config bsp_split_mode                optimal
      chunkc config bsp_split_ratio               0.66

      chunkc config window_focus_cycle            all
      chunkc config mouse_follows_focus           1
      chunkc config window_float_next             0
      chunkc config window_float_center           1
      chunkc config window_region_locked          1

      # signal dock to make windows topmost when floated
      # requires chwm-sa (https://github.com/koekeishiya/chwm-sa)
      chunkc config window_float_topmost          0

      # section - window rules

      # regex filters (pattern is case sensitive):
      #  --owner  | -o  (application name matches pattern)
      #  --name   | -n  (window name matches pattern)
      #  --except | -e  (window name does not match pattern)

      # properties:
      #  --state | -s
      #   values:
      #    float
      #    tile

      chunkc rule --owner "System Preferences" --state tile
      chunkc rule --owner Finder --name Copy --state float
      '';
    };

  };

  config = mkIf cfg.enable {

    security.accessibilityPrograms = [ "${cfg.package}/chunkwm" ];

    environment.etc."chunkwmrc".text = ''
      #!/bin/bash
      export CHUNKC_SOCKET=${toString cfg.port}
      chunkc plugin_dir ${toString cfg.plugins.dir}
      chunkc hotload ${if cfg.hotload then "1" else "0"}
      ${foldl (p1: p2: "${p1}\n${p2}") "" (map (p: "chunkc load "+p+".so") cfg.plugins.list)}
    '';

    environment.etc."chunkwmtilingrc".text = cfg.plugins.tiling.config;

    launchd.user.agents.chunkwm = {
      path = [ cfg.package pkgs.chunkwm-core config.environment.systemPath ];
      serviceConfig.Program = "${cfg.package}/bin/chunkwm";
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive = true;
      serviceConfig.ProcessType = "Interactive";
    };

  };
}
