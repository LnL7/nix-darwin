{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.system.keyboard;

  globalKeyMappings = { }
    // (if cfg.remapCapsLockToControl then { "Keyboard Caps Lock" = "Keyboard Left Control"; } else { })
    // (if cfg.remapCapsLockToEscape then { "Keyboard Caps Lock" = "Keyboard Escape"; } else { })
    // (if cfg.nonUS.remapTilde then { "Keyboard Non-US # and ~" = "Keyboard Grave Accent and Tilde"; } else { });

  keyMappingTable = (
    mapAttrs
      (name: value:
        # hidutil accepts values that consists of 0x700000000 binary ORed with the
        # desired keyboard usage value.
        #
        # The actual number can be base-10 or hexadecimal.
        # 0x700000000
        #
        # 30064771072 == 0x700000000
        #
        # https://developer.apple.com/library/archive/technotes/tn2450/_index.html
        bitOr 30064771072 value)
      (import ./hid-usage-table.nix)
  ) // {
    # These are not documented, but they work with hidutil.
    #
    # Sources:
    # https://apple.stackexchange.com/a/396863/383501
    # http://www.neko.ne.jp/~freewing/software/macos_keyboard_setting_terminal_commandline/
    "Keyboard Left Function (fn)" = 1095216660483;
    "Keyboard Right Function (fn)" = 280379760050179;
  };

  keyMappingTableKeys = attrNames keyMappingTable;

  isValidKeyMapping = key: elem key keyMappingTableKeys;

  xpc_set_event_stream_handler =
    pkgs.callPackage
      ./xpc_set_event_stream_handler.nix {
      inherit (pkgs.darwin.apple_sdk.frameworks) Foundation;
    };

  mappingOptions = types.submodule {
    options = {
      productId = mkOption {
        type = types.int;
        description = '';
          Product ID of the keyboard which should have this mapping applied.  To find the Product ID of a keyboard, you can check the output of <literal>hidutil list --matching keyboard</literal>.

          Note that you have to convert the value from hexadecimal to decimal because Nix only has base 10 integers.  For example: <literal>printf "%d" 0x27e</literal>
        '';
      };

      vendorId = mkOption {
        type = types.int;
        description = '';
          Vendor ID of the keyboard which should have this mapping applied.  To find the Vendor ID of a keyboard, you can check the output of <literal>hidutil list --matching keyboard</literal>.

          Note that you have to convert the value from hexadecimal to decimal because Nix only has base 10 integers.  For example: <literal>printf "%d" 0x5ac</literal>
        '';
      };

      mappings = mkOption {
        type = types.attrsOf (types.enum keyMappingTableKeys);
        description = ''
          Mappings that should be applied.  To see what values are available, check <link xlink:href="https://github.com/LnL7/nix-darwin/blob/master/modules/system/keyboard/hid-usage-table.nix"/>.
        '';
      };
    };
  };
in
{
  options = {
    system.keyboard.enableKeyMapping = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable keyboard mappings.";
    };

    system.keyboard.remapCapsLockToControl = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to remap the Caps Lock key to Control.";
    };

    system.keyboard.remapCapsLockToEscape = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to remap the Caps Lock key to Escape.";
    };

    system.keyboard.nonUS.remapTilde = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to remap the Tilde key on non-us keyboards.";
    };

    system.keyboard.mappings = mkOption {
      type = types.nullOr (types.either mappingOptions (types.listOf mappingOptions));
      default = null;
      description = ''
        Either an attribute set of key mappings (that will be applied to all keyboards), or a list of attribute sets of key mappings (mappings that will be applied to keyboards with specific Product IDs).
      '';
      example = literalExample ''
        system.keyboard.enableKeyMapping = true;
        system.keyboard.mappings = [
          {
            productId = 273;
            vendorId = 2131;
            mappings = {
              "Keyboard Caps Lock" = "Keyboard Left Function (fn)";
            };
          }
          {
            productId = 638;
            vendorId = 1452;
            mappings = {
              # For the built-in MacBook keyboard, change the modifiers to match a
              # traditional keyboard layout.
              "Keyboard Caps Lock" = "Keyboard Left Function (fn)";
              "Keyboard Left Alt" = "Keyboard Left GUI";
              "Keyboard Left Function (fn)" = "Keyboard Left Control";
              "Keyboard Left GUI" = "Keyboard Left Alt";
              "Keyboard Right Alt" = "Keyboard Right Control";
              "Keyboard Right GUI" = "Keyboard Right Alt";
            };
          }
        ];
      '';
    };
  };

  config = {

    assertions =
      let
        mkAssertion = { element, productId ? null, ... }: {
          assertion = isValidKeyMapping element;
          message = "${element} ${if productId != null then "in mapping for ${productId}" else ""} must be one of ${builtins.toJSON keyMappingTableKeys}";
        };
      in
      (
        flatten (optionals (cfg.mappings != null) (
          map
            ({ productId, mappings, ... }:
              (mapAttrsToList
                (src: dest: [
                  (mkAssertion { inherit productId; element = src; })
                  (mkAssertion { inherit productId; element = dest; })
                ])
                mappings
              )
            )
            cfg.mappings
        ) ++ (
          mapAttrsToList
            (src: dest: [
              (mkAssertion { element = src; })
              (mkAssertion { element = dest; })
            ])
            globalKeyMappings
        )) ++ [
          {
            assertion = !(cfg.mappings != null && (length (attrNames globalKeyMappings) > 0));
            message = "Configuring both global and device-specific key mappings is not reliable, please use one or the other.";
          }
        ]
      );

    warnings = [ ]
      ++ (
      optional
        (!cfg.enableKeyMapping && (cfg.mappings != null || globalKeyMappings != { }))
        "system.keyboard.enableKeyMapping is false, keyboard mappings will not be configured."
    )
      ++ (
      optional
        (cfg.enableKeyMapping && (cfg.mappings == null && globalKeyMappings == { }))
        "system.keyboard.enableKeyMapping is true but you have not configured any key mappings."
    );

    launchd.user.agents =
      let
        mkUserKeyMapping = mapping: builtins.toJSON ({
          UserKeyMapping = (
            mapAttrsToList
              (src: dst: {
                HIDKeyboardModifierMappingSrc = keyMappingTable."${src}";
                HIDKeyboardModifierMappingDst = keyMappingTable."${dst}";
              })
              mapping
          );
        });
      in
      if (cfg.enableKeyMapping && length (attrNames globalKeyMappings) > 0) then
        {
          keyboard = ({
            serviceConfig.ProgramArguments = [
              "${xpc_set_event_stream_handler}/bin/xpc_set_event_stream_handler"
              "${pkgs.writeScriptBin "apply-keybindings" ''
                  #!${pkgs.stdenv.shell}
                  set -euo pipefail

                  echo "$(date) configuring keyboard..." >&2
                  hidutil property --set '${mkUserKeyMapping globalKeyMappings}' > /dev/null
                ''}/bin/apply-keybindings"
            ];
            serviceConfig.LaunchEvents = {
              "com.apple.iokit.matching" = {
                "com.apple.usb.device" = {
                  IOMatchLaunchStream = true;
                  IOProviderClass = "IOUSBDevice";
                  idProduct = "*";
                  idVendor = "*";
                };
              };
            };
            serviceConfig.RunAtLoad = true;
          });
        }
      else if (cfg.enableKeyMapping && cfg.mappings != null) then (listToAttrs (map
        ({ mappings
         , productId
         , vendorId
         , ...
         }: (nameValuePair "keyboard-${toString productId}" ({
          serviceConfig.ProgramArguments = [
            # Use xpc_set_event_stream_handler to mark this event as "consumed",
            # otherwise it the script will never stop being called (something
            # like every 10 seconds).
            "${xpc_set_event_stream_handler}/bin/xpc_set_event_stream_handler"
            "${pkgs.writeScriptBin "apply-keybindings" (
                let intToHexString = value:
                  pkgs.runCommand "${toString value}-to-hex-string"
                      { } ''printf "%#0x" ${toString value} > $out''; in
                ''
                  #!${pkgs.stdenv.shell}
                  set -euxo pipefail

                  # Sometimes it takes a moment for the keyboard to be
                  # visible to hidutil, even when the script is launched
                  # with "LaunchEvents".
                  function retry () {
                    local attempt=1
                    local max_attempts=10
                    local delay=0.2

                    while true; do
                      "$@" && break || {
                        if (test $attempt -lt $max_attempts); then
                          attempt=$((attempt + 1))
                          sleep $delay
                        else
                          exit 1
                        fi
                      }
                    done
                  }

                  function get_vendor_id () {
                    hidutil list --matching keyboard |
                      awk '{ print $1 }' |
                      grep $(<${intToHexString vendorId})
                  }

                  function get_product_id () {
                    hidutil list --matching keyboard |
                      awk '{ print $2 }' |
                      grep $(<${intToHexString productId})
                  }

                  echo "$(date) configuring keyboard ${toString productId} ($(<${intToHexString productId}))..." >&2

                  retry get_vendor_id
                  retry get_product_id

                  hidutil property --matching '${builtins.toJSON { ProductID = productId; }}' --set '${mkUserKeyMapping mappings}' > /dev/null
                ''
                )}/bin/apply-keybindings"
          ];
          serviceConfig.LaunchEvents = {
            "com.apple.iokit.matching" = {
              "com.apple.usb.device" = {
                IOMatchLaunchStream = true;
                IOProviderClass = "IOUSBDevice";
                idProduct = productId;
                idVendor = vendorId;
              };
            };
          };
          serviceConfig.RunAtLoad = true;
        })
        ))
        cfg.mappings
      )) else { };
  };
}
