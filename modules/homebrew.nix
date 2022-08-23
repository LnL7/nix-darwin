# Created by: https://github.com/malob
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homebrew;

  mkBrewfileSectionString = heading: type: entries: optionalString (entries != []) ''
    # ${heading}
    ${concatMapStringsSep "\n" (v: v.brewfileLine or ''${type} "${v}"'') entries}

  '';

  mkMasBrewfileSectionString = entries: optionalString (entries != {}) (
    "# Mac App Store apps\n" +
    concatStringsSep "\n" (mapAttrsToList (name: id: ''mas "${name}", id: ${toString id}'') entries) +
    "\n"
  );


  brewfile = pkgs.writeText "Brewfile" (
    mkBrewfileSectionString "Taps" "tap" cfg.taps +
    mkBrewfileSectionString "Arguments for all casks" "cask_args"
      (optional (cfg.caskArgs.brewfileLine != null) cfg.caskArgs) +
    mkBrewfileSectionString "Brews" "brew" cfg.brews +
    mkBrewfileSectionString "Casks" "cask" cfg.casks +
    mkMasBrewfileSectionString cfg.masApps +
    mkBrewfileSectionString "Docker containers" "whalebrew" cfg.whalebrews +
    optionalString (cfg.extraConfig != "") ("# Extra config\n" + cfg.extraConfig)
  );

  brew-bundle-command = concatStringsSep " " (
    optional (!cfg.autoUpdate) "HOMEBREW_NO_AUTO_UPDATE=1" ++
    [ "brew bundle --file='${brewfile}' --no-lock" ] ++
    optional (cfg.cleanup == "uninstall" || cfg.cleanup == "zap") "--cleanup" ++
    optional (cfg.cleanup == "zap") "--zap"
  );

  mkBrewfileLineValueString = v:
    if isInt v then toString v
    else if isFloat v then strings.floatToString v
    else if isBool v then boolToString v
    else if isString v then ''"${v}"''
    else if isAttrs v then "{ ${concatStringsSep ", " (mapAttrsToList (n: v': "${n}: ${mkBrewfileLineValueString v'}") v)} }"
    else if isList v then "[${concatMapStringsSep ", " mkBrewfileLineValueString v}]"
    else abort "The value: ${generators.toPretty v} is not a valid Brewfile value.";

  mkBrewfileLineOptionsListString = attrs:
    concatStringsSep ", " (mapAttrsToList (n: v: "${n}: ${mkBrewfileLineValueString v}") attrs);

  mkNullOrBoolOption = args: mkOption (args // {
    type = types.nullOr types.bool;
    default = null;
  });

  mkNullOrStrOption = args: mkOption (args // {
    type = types.nullOr types.str;
    default = null;
  });

  mkBrewfileLineOption = mkOption {
    type = types.nullOr types.str;
    visible = false;
    internal = true;
    readOnly = true;
  };

  tapOptions = { config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        example = "homebrew/cask-fonts";
        description = ''
          When <option>clone_target</option> is unspecified, this is the name of a formula
          repository to tap from GitHub using HTTPS. For example, <literal>"user/repo"</literal> will
          tap https://github.com/user/homebrew-repo.
        '';
      };
      clone_target = mkNullOrStrOption {
        description = ''
          Use this option to tap a formula repository from anywhere, using any transport protocol
          that <command>git</command> handles. When <option>clone_target</option> is specified, taps
          can be cloned from places other than GitHub and using protocols other than HTTPS, e.g.,
          SSH, git, HTTP, FTP(S), rsync.
        '';
      };
      force_auto_update = mkNullOrBoolOption {
        description = ''
          Whether to auto-update the tap even if it is not hosted on GitHub. By default, only taps
          hosted on GitHub are auto-updated (for performance reasons).
        '';
      };

      brewfileLine = mkBrewfileLineOption;
    };

    config = {
      brewfileLine = ''tap "${config.name}"''
        + optionalString (config.clone_target != null) '', "${config.clone_target}"''
        + optionalString (config.force_auto_update != null)
          ", force_auto_update: ${boolToString config.force_auto_update}";
    };
  };

  # Sourced from https://docs.brew.sh/Manpage#global-cask-options
  # and valid values for `HOMEBREW_CASK_OPTS`.
  caskArgsOptions = { config, ... }: {
    options = {
      appdir = mkNullOrStrOption {
        description = ''
          Target location for Applications
          (default: <filename class='directory'>/Applications</filename>)
        '';
      };
      colorpickerdir = mkNullOrStrOption {
        description = ''
          Target location for Color Pickers
          (default: <filename class='directory'>~/Library/ColorPickers</filename>)
        '';
      };
      prefpanedir = mkNullOrStrOption {
        description = ''
          Target location for Preference Panes
          (default: <filename class='directory'>~/Library/PreferencePanes</filename>)
        '';
      };
      qlplugindir = mkNullOrStrOption {
        description = ''
          Target location for QuickLook Plugins
          (default: <filename class='directory'>~/Library/QuickLook</filename>)
        '';
      };
      mdimporterdir = mkNullOrStrOption {
        description = ''
          Target location for Spotlight Plugins
          (default: <filename class='directory'>~/Library/Spotlight</filename>)
        '';
      };
      dictionarydir = mkNullOrStrOption {
        description = ''
          Target location for Dictionaries
          (default: <filename class='directory'>~/Library/Dictionaries</filename>)
        '';
      };
      fontdir = mkNullOrStrOption {
        description = ''
          Target location for Fonts
          (default: <filename class='directory'>~/Library/Fonts</filename>)
        '';
      };
      servicedir = mkNullOrStrOption {
        description = ''
          Target location for Services
          (default: <filename class='directory'>~/Library/Services</filename>)
        '';
      };
      input_methoddir = mkNullOrStrOption {
        description = ''
          Target location for Input Methods
          (default: <filename class='directory'>~/Library/Input Methods</filename>)
        '';
      };
      internet_plugindir = mkNullOrStrOption {
        description = ''
          Target location for Internet Plugins
          (default: <filename class='directory'>~/Library/Internet Plug-Ins</filename>)
        '';
      };
      audio_unit_plugindir = mkNullOrStrOption {
        description = ''
          Target location for Audio Unit Plugins
          (default: <filename class='directory'>~/Library/Audio/Plug-Ins/Components</filename>)
        '';
      };
      vst_plugindir = mkNullOrStrOption {
        description = ''
          Target location for VST Plugins
          (default: <filename class='directory'>~/Library/Audio/Plug-Ins/VST</filename>)
        '';
      };
      vst3_plugindir = mkNullOrStrOption {
        description = ''
          Target location for VST3 Plugins
          (default: <filename class='directory'>~/Library/Audio/Plug-Ins/VST3</filename>)
        '';
      };
      screen_saverdir = mkNullOrStrOption {
        description = ''
          Target location for Screen Savers
          (default: <filename class='directory'>~/Library/Screen Savers</filename>)
        '';
      };
      language = mkNullOrStrOption {
        description = ''
          Comma-separated list of language codes to prefer for cask installation. The first matching
          language is used, otherwise it reverts to the cask’s default language. The default value
          is the language of your system.
        '';
        example = "zh-TW";
      };
      require_sha = mkNullOrBoolOption {
        description = "Whether to require cask(s) to have a checksum.";
      };
      no_quarantine = mkNullOrBoolOption {
        description = "Whether to disable quarantining of downloads.";
      };
      no_binaries = mkNullOrBoolOption {
        description = "Whether to disable linking of helper executables.";
      };

      brewfileLine = mkBrewfileLineOption;
    };

    config =
      let
        configuredOptions = filterAttrs (_: v: v != null)
          (removeAttrs config [ "_module" "brewfileLine" ]);
      in
      {
        brewfileLine =
          if configuredOptions == {} then null
          else "cask_args " + mkBrewfileLineOptionsListString configuredOptions;
      };
  };
in

{
  options.homebrew = {
    enable = mkEnableOption ''
      configuring your Brewfile, and installing/updating the formulas therein via
      the <command>brew bundle</command> command, using <command>nix-darwin</command>.

      Note that enabling this option does not install Homebrew. See the Homebrew website for
      installation instructions: https://brew.sh
    '';

    autoUpdate = mkOption {
      type = types.bool;
      default = false;
      description = ''
        When enabled, Homebrew is allowed to auto-update during <command>nix-darwin</command>
        activation. The default is <literal>false</literal> so that repeated invocations of
        <command>darwin-rebuild switch</command> are idempotent.
      '';
    };

    brewPrefix = mkOption {
      type = types.str;
      default = if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew/bin" else "/usr/local/bin";
      description = ''
        Customize path prefix where executable of <command>brew</command> is searched for.
      '';
    };

    cleanup = mkOption {
      type = types.enum [ "none" "uninstall" "zap" ];
      default = "none";
      example = "uninstall";
      description = ''
        This option manages what happens to formulas installed by Homebrew, that aren't present in
        the Brewfile generated by this module.

        When set to <literal>"none"</literal> (the default), formulas not present in the generated
        Brewfile are left installed.

        When set to <literal>"uninstall"</literal>, <command>nix-darwin</command> invokes
        <command>brew bundle [install]</command> with the <command>--cleanup</command> flag. This
        uninstalls all formulas not listed in generate Brewfile, i.e.,
        <command>brew uninstall</command> is run for those formulas.

        When set to <literal>"zap"</literal>, <command>nix-darwin</command> invokes
        <command>brew bundle [install]</command> with the <command>--cleanup --zap</command>
        flags. This uninstalls all formulas not listed in the generated Brewfile, and if the
        formula is a cask, removes all files associated with that cask. In other words,
        <command>brew uninstall --zap</command> is run for all those formulas.

        If you plan on exclusively using <command>nix-darwin</command> to manage formulas installed
        by Homebrew, you probably want to set this option to <literal>"uninstall"</literal> or
        <literal>"zap"</literal>.
      '';
    };

    global.brewfile = mkOption {
      type = types.bool;
      default = false;
      description = ''
        When enabled, when you manually invoke <command>brew bundle</command>, it will automatically
        use the Brewfile in the Nix store that this module generates.

        Sets the <literal>HOMEBREW_BUNDLE_FILE</literal> environment variable to the path of the
        Brewfile in the Nix store that this module generates, by adding it to
        <option>environment.variables</option>.
      '';
    };

    global.noLock = mkOption {
      type = types.bool;
      default = false;
      description = ''
        When enabled, lockfiles aren't generated when you manually invoke
        <command>brew bundle [install]</command>. This is often desirable when
        <option>homebrew.global.brewfile</option> is enabled, since
        <command>brew bundle [install]</command> will try to write the lockfile in the Nix store,
        and complain that it can't (though the command will run successfully regardless).

        Sets the <literal>HOMEBREW_BUNDLE_NO_LOCK</literal> environment variable, by adding it to
        <option>environment.variables</option>.
      '';
    };

    taps = mkOption {
      type = with types; listOf (coercedTo str (name: { inherit name; }) (submodule tapOptions));
      default = [];
      example = literalExpression ''
        # Adapted examples from https://github.com/Homebrew/homebrew-bundle#usage
        [
          # 'brew tap'
          "homebrew/cask"
          # 'brew tap' with custom Git URL and arguments
          {
            name = "user/tap-repo";
            clone_target = "https://user@bitbucket.org/user/homebrew-tap-repo.git";
            force_auto_update = true;
          }
        ]
      '';
      description = ''
        Homebrew formula repositories to tap.

        Taps defined as strings, e.g., <literal>"user/repo"</literal>, are a shorthand for:

        <code>{ name = "user/repo"; }</code>
      '';
    };

    brews = mkOption {
      type = with types; listOf str;
      default = [];
      example = [ "mas" ];
      description = "Homebrew brews to install.";
    };

    caskArgs = mkOption {
      type = types.submodule caskArgsOptions;
      default = {};
      example = {
        appdir = "~/Applications";
        require_sha = true;
      };
      description = "Arguments to apply to all <option>homebrew.casks</option>.";
    };

    casks = mkOption {
      type = with types; listOf str;
      default = [];
      example = [ "hammerspoon" "virtualbox" ];
      description = "Homebrew casks to install.";
    };

    masApps = mkOption {
      type = with types; attrsOf ints.positive;
      default = {};
      example = {
        "1Password" = 1107421413;
        Xcode = 497799835;
      };
      description = ''
        Applications to install from Mac App Store using <command>mas</command>.

        When this option is used, <literal>"mas"</literal> is automatically added to
        <option>homebrew.brews</option>.

        Note that you need to be signed into the Mac App Store for <command>mas</command> to
        successfully install and upgrade applications, and that unfortunately apps removed from this
        option will not be uninstalled automatically even if
        <option>homebrew.cleanup</option> is set to <literal>"uninstall"</literal>
        or <literal>"zap"</literal> (this is currently a limitation of Homebrew Bundle).

        For more information on <command>mas</command> see: https://github.com/mas-cli/mas.
      '';
    };

    whalebrews = mkOption {
      type = with types; listOf str;
      default = [];
      example = [ "whalebrew/wget" ];
      description = ''
        Docker images to install using <command>whalebrew</command>.

        When this option is used, <literal>"whalebrew"</literal> is automatically added to
        <option>homebrew.brews</option>.

        For more information on <command>whalebrew</command> see:
        https://github.com/whalebrew/whalebrew.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        # 'brew install --with-rmtp', 'brew services restart' on version changes
        brew "denji/nginx/nginx-full", args: ["with-rmtp"], restart_service: :changed
        # 'brew install', always 'brew services restart', 'brew link', 'brew unlink mysql' (if it is installed)
        brew "mysql@5.6", restart_service: true, link: true, conflicts_with: ["mysql"]

        # 'brew cask install --appdir=~/my-apps/Applications'
        cask "firefox", args: { appdir: "~/my-apps/Applications" }
        # 'brew cask install' only if '/usr/libexec/java_home --failfast' fails
        cask "java" unless system "/usr/libexec/java_home --failfast"
      '';
      description = "Extra lines to be added verbatim to the generated Brewfile.";
    };
  };

  config = {
    homebrew.brews =
      optional (cfg.masApps != {}) "mas" ++
      optional (cfg.whalebrews != []) "whalebrew";

    environment.variables = mkIf cfg.enable (
       optionalAttrs cfg.global.brewfile { HOMEBREW_BUNDLE_FILE = "${brewfile}"; } //
       optionalAttrs cfg.global.noLock { HOMEBREW_BUNDLE_NO_LOCK = "1"; }
     );

    system.activationScripts.homebrew.text = mkIf cfg.enable ''
      # Homebrew Bundle
      echo >&2 "Homebrew bundle..."
      if [ -f "${cfg.brewPrefix}/brew" ]; then
        PATH="${cfg.brewPrefix}":$PATH ${brew-bundle-command}
      else
        echo -e "\e[1;31merror: Homebrew is not installed, skipping...\e[0m" >&2
      fi
    '';
  };
}
