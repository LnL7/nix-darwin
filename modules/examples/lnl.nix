{ config, lib, pkgs, ... }:

{
  # imports = [ ~/.config/nixpkgs/darwin/local-configuration.nix ];

  system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 10;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;

  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "left";
  system.defaults.dock.showhidden = true;
  system.defaults.dock.mru-spaces = false;

  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder.QuitMenuItem = true;
  system.defaults.finder.FXEnableExtensionChangeWarning = false;

  system.defaults.trackpad.Clicking = true;
  system.defaults.trackpad.TrackpadThreeFingerDrag = true;

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

  environment.systemPackages =
    [ config.programs.vim.package
      config.services.chunkwm.package

      pkgs.awscli
      pkgs.bear
      pkgs.brotli
      # pkgs.cachix
      pkgs.ctags
      pkgs.curl
      pkgs.direnv
      pkgs.fzf
      pkgs.gettext
      pkgs.git
      pkgs.gnupg
      pkgs.htop
      pkgs.jq
      pkgs.mosh
      pkgs.ripgrep
      pkgs.shellcheck
      pkgs.silver-searcher
      pkgs.vault

      pkgs.qes
      pkgs.darwin-zsh-completions
    ];

  services.chunkwm.enable = true;
  services.skhd.enable = true;

  security.sandbox.profiles.fetch-nixpkgs-updates.closure = [ pkgs.cacert pkgs.git ];
  security.sandbox.profiles.fetch-nixpkgs-updates.writablePaths = [ "/src/nixpkgs" ];
  security.sandbox.profiles.fetch-nixpkgs-updates.allowNetworking = true;

  launchd.user.agents.fetch-nixpkgs-updates = {
    command = "/usr/bin/sandbox-exec -f ${config.security.sandbox.profiles.fetch-nixpkgs-updates.profile} ${pkgs.git}/bin/git -C /src/nixpkgs fetch origin master";
    environment.HOME = "";
    environment.NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    serviceConfig.KeepAlive = false;
    serviceConfig.ProcessType = "Background";
    serviceConfig.StartInterval = 360;
  };

  services.nix-daemon.enable = true;
  services.nix-daemon.enableSocketListener = true;
  # FIXME workaround for https://github.com/NixOS/nix/issues/2523
  # launchd.daemons.nix-daemon.environment.OBJC_DISABLE_INITIALIZE_FORK_SAFETY = "YES";

  nix.extraOptions = ''
    gc-keep-derivations = true
    gc-keep-outputs = true
    log-lines = 128
  '';

  nix.binaryCachePublicKeys = [ "cache.daiderd.com-1:R8KOWZ8lDaLojqD+v9dzXAqGn29gEzPTTbr/GIpCTrI=" ];
  nix.trustedBinaryCaches = [ https://d3i7ezr9vxxsfy.cloudfront.net ];
  nix.trustedUsers = [ "@admin" ];

  nix.useSandbox = true;
  nix.sandboxPaths = [ "/System/Library/Frameworks" "/System/Library/PrivateFrameworks" "/usr/lib" "/private/tmp" "/private/var/tmp" "/usr/bin/env" ];

  programs.nix-index.enable = true;

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;

  programs.tmux.enable = true;
  programs.tmux.enableSensible = true;
  programs.tmux.enableMouse = true;
  programs.tmux.enableFzf = true;
  programs.tmux.enableVim = true;

  programs.tmux.tmuxConfig = ''
    bind 0 set status
    bind S choose-session

    bind-key -r "<" swap-window -t -1
    bind-key -r ">" swap-window -t +1

    bind-key -n M-r run "tmux send-keys -t .+ C-l Up Enter"
    bind-key -n M-t run "tmux send-keys -t _ C-l Up Enter"

    set -g pane-active-border-style fg=black
    set -g pane-border-style fg=black
    set -g status-bg black
    set -g status-fg white
    set -g status-right '#[fg=white]#(id -un)@#(hostname)   #(cat /run/current-system/darwin-version)'
  '';

  environment.etc."nix/user-sandbox.sb".text = ''
    (version 1)
    (allow default)
    (deny file-write*
          (subpath "/nix"))
    (allow file-write*
           (subpath "/nix/var/nix/gcroots/per-user")
           (subpath "/nix/var/nix/profiles/per-user"))
  '';

  # programs.vim.enable = true;
  # programs.vim.enableSensible = true;
  programs.vim.package = pkgs.vim_configurable.customize {
    name = "vim";
    vimrcConfig.packages.darwin.start = with pkgs.vimPlugins; [
      vim-sensible vim-surround ReplaceWithRegister
      polyglot fzfWrapper YouCompleteMe ale
    ];
    vimrcConfig.packages.darwin.opt = with pkgs.vimPlugins; [
      colors-solarized
      splice-vim
    ];
    vimrcConfig.customRC = ''
      set completeopt=menuone
      set encoding=utf-8
      set hlsearch
      set list
      set number
      set showcmd
      set splitright

      nnoremap // :nohlsearch<CR>

      let mapleader = ' '

      " fzf
      nnoremap <Leader>p :FZF<CR>

      " vim-surround
      vmap s S

      " youcompleteme
      let g:ycm_seed_identifiers_with_syntax = 1
    '';
  };

  # Dotfiles.
  # programs.vim.package = mkForce pkgs.lnl.vim;

  programs.bash.enableCompletion = true;

  programs.zsh.enable = true;
  programs.zsh.enableBashCompletion = true;
  programs.zsh.enableFzfCompletion = true;
  programs.zsh.enableFzfGit = true;
  programs.zsh.enableFzfHistory = true;

  programs.zsh.variables.cfg = "$HOME/.config/nixpkgs/darwin/configuration.nix";
  programs.zsh.variables.darwin = "$HOME/.nix-defexpr/darwin";
  programs.zsh.variables.nixpkgs = "$HOME/.nix-defexpr/nixpkgs";


  programs.zsh.promptInit = ''
    autoload -U promptinit && promptinit

    setopt PROMPTSUBST

    _prompt_nix() {
      [ -z "$IN_NIX_SHELL" ] || echo "%F{yellow}%B[''${name:+$name}]%b%f "
    }

    PS1='%F{red}%B%(?..%? )%b%f%# '
    RPS1='$(_prompt_nix)%F{green}%~%f'

    if [ -n "$IN_NIX_SANDBOX" ]; then
      PS1+='%F{red}[sandbox]%f '
    fi
  '';

  programs.zsh.loginShellInit = ''
    :a() {
        nix repl ''${@:-<dotpkgs>}
    }

    :d() {
        eval "$(direnv hook zsh)"
    }

    :r() {
        direnv reload
    }

    :u() {
        local exports

        exports=$(direnv apply_dump <(nix-shell -E "with import <dotpkgs> {}; mkShell { buildInputs = [ $* ]; }" --run 'direnv dump'))
        eval "$exports"

        name+="''${name:+ }$*"
        typeset -U PATH
    }

    xi() {
        curl -F 'f:1=<-' ix.io
    }

    mount_ram() {
        local dev
        if [ -e /Volumes/RAM ]; then
            dev=$(diskutil info | awk '/Device Node:/ {print $3}')
            umount /Volumes/RAM
            hdiutil detach "$dev"
        fi
        diskutil erasevolume JHFS+ RAM $(hdiutil attach -nomount ram://10248576)
    }

    ls() {
        ${pkgs.coreutils}/bin/ls --color=auto "$@"
    }

    install_name_tool() {
        ${pkgs.darwin.cctools}/bin/install_name_tool "$@"
    }

    nm() {
        ${pkgs.darwin.cctools}/bin/nm "$@"
    }

    otool() {
        ${pkgs.darwin.cctools}/bin/otool "$@"
    }

    aarch-build() {
        nix-build --option system aarch64-linux --store ssh-ng://aarch1 "$@"
    }

    arm-build() {
        nix-build --option system armv7l-linux --store ssh-ng://arm1 "$@"
    }

    darwin-build() {
        nix-build --option system x86_64-darwin --store ssh-ng://mac1 "$@"
    }

    linux-build() {
        nix-build --option system x86_64-linux --store ssh-ng://nixos1 "$@"
    }

    nix-unpack() {
        nix-shell --run 'phases=unpackPhase genericBuild' "$@"
    }

    hydra-bad-machines() {
        local url=https://hydra.nixos.org
        curl -fsSL -H 'Accept: application/json' $url/queue-runner-status | jq -r '.machines | to_entries | .[] | select(.value.consecutiveFailures>0) | .key'
    }

    hydra-job-revision() {
        local jobseteval job=$1
        shift 1
        case "$job" in
            *'/'*) ;;
            *) job="nixpkgs/trunk/$job" ;;
        esac
        case "$job" in
            'http://'*|'https://'*) ;;
            *) job="https://hydra.nixos.org/job/$job" ;;
        esac
        jobseteval=$(curl -fsSL -H 'Content-Type: application/json' "$job/latest" | jq '.jobsetevals[0]')
        curl -fsSL -H 'Accept: application/json' "''${job%/job*}/eval/$jobseteval" | jq -r '.jobsetevalinputs.nixpkgs.revision'
    }

    hydra-job-bisect() {
        local job=$1
        shift 1
        nix-build ./pkgs/top-level/release.nix -A "''${job##*/}" --dry-run "$@" || return
        git bisect start HEAD "$(hydra-job-revision "$job")"
        git bisect run nix-build ./pkgs/top-level/release.nix -A "''${job##*/}" "$@"
    }

    hydra-job-outputs() {
        local job=$1
        shift 1
        curl -fsSL -H 'Accept: application/json' "$job/latest" | jq -r '.buildoutputs | to_entries | .[].value.path'
    }

    hydra-build-log() {
        local build=$1
        shift 1
        nix log "$(curl -fsSL -H 'Accept: application/json' "$build/api/get-info" | jq -r .drvPath)"
    }

    rev-darwin() {
        echo "https://github.com/LnL7/nix-darwin/archive/''${@:-master}.tar.gz"
    }

    rev-nixpkgs() {
        echo "https://github.com/NixOS/nixpkgs/archive/''${@:-master}.tar.gz"
    }

    pr-nixpkgs() {
        local pr=$1
        shift 1
        rev-nixpkgs "$(curl "https://api.github.com/repos/NixOS/nixpkgs/pulls/$pr/commits" | jq -r '.[-1].sha')"
    }

    reexec() {
        unset __NIX_DARWIN_SET_ENVIRONMENT_DONE
        unset __ETC_ZPROFILE_SOURCED __ETC_ZSHENV_SOURCED __ETC_ZSHRC_SOURCED
        exec $SHELL -c 'echo >&2 "reexecuting shell: $SHELL" && exec $SHELL -l'
    }

    reexec-tmux() {
        unset __NIX_DARWIN_SET_ENVIRONMENT_DONE
        unset __ETC_ZPROFILE_SOURCED __ETC_ZSHENV_SOURCED __ETC_ZSHRC_SOURCED
        exec tmux new-session -A -s _ "$@"
    }

    reexec-sandbox() {
        unset __NIX_DARWIN_SET_ENVIRONMENT_DONE
        unset __ETC_ZPROFILE_SOURCED __ETC_ZSHENV_SOURCED __ETC_ZSHRC_SOURCED
        export IN_NIX_SANDBOX=1
        exec /usr/bin/sandbox-exec -f /etc/nix/user-sandbox.sb $SHELL -l
    }

    no-sandbox() {
        tmux split-window -c '#{pane_current_path}' -p 25
        if [ $# -gt 0 ]; then
            tmux send-keys -t . "$*" Enter
        fi
    }
  '';

  programs.zsh.interactiveShellInit = ''
    setopt AUTOCD AUTOPUSHD

    autoload -U down-line-or-beginning-search
    autoload -U up-line-or-beginning-search
    bindkey '^[[A' down-line-or-beginning-search
    bindkey '^[[A' up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    zle -N up-line-or-beginning-search
  '';

  environment.variables.LANG = "en_US.UTF-8";

  environment.shellAliases.g = "git log --pretty=color -32";
  environment.shellAliases.gb = "git branch";
  environment.shellAliases.gc = "git checkout";
  environment.shellAliases.gcb = "git checkout -B";
  environment.shellAliases.gd = "git diff --minimal --patch";
  environment.shellAliases.gf = "git fetch";
  environment.shellAliases.gg = "git log --pretty=color --graph";
  environment.shellAliases.gl = "git log --pretty=nocolor";
  environment.shellAliases.grh = "git reset --hard";
  environment.shellAliases.l = "ls -lh";

  environment.extraInit = ''
    # Load and export variables from environment.d.
    if [ -d /etc/environment.d ]; then
        set -a
        . /etc/environment.d/*
        set +a
    fi
  '';

  environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  nix.nixPath =
    [{ # Use local nixpkgs checkout instead of channels.
      darwin-config = "$HOME/.config/nixpkgs/darwin/configuration.nix";
      darwin = "$HOME/.nix-defexpr/darwin"; }
    ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (self: super: {
      darwin-zsh-completions = super.runCommandNoCC "darwin-zsh-completions-0.0.0"
        { preferLocalBuild = true; }
        ''
          mkdir -p $out/share/zsh/site-functions

          cat <<-'EOF' > $out/share/zsh/site-functions/_darwin-rebuild
          #compdef darwin-rebuild
          #autoload

          _nix-common-options

          local -a _1st_arguments
          _1st_arguments=(
            'switch:Build, activate, and update the current generation'\
            'build:Build without activating or updating the current generation'\
            'check:Build and run the activation sanity checks'\
            'changelog:Show most recent entries in the changelog'\
          )

          _arguments \
            '--list-generations[Print a list of all generations in the active profile]'\
            '--rollback[Roll back to the previous configuration]'\
            {--switch-generation,-G}'[Activate specified generation]'\
            '(--profile-name -p)'{--profile-name,-p}'[Profile to use to track current and previous system configurations]:Profile:_nix_profiles'\
            '1:: :->subcmds' && return 0

          case $state in
            subcmds)
              _describe -t commands 'darwin-rebuild subcommands' _1st_arguments
            ;;
          esac
          EOF
        '';

      vim_configurable = super.vim_configurable.override {
        guiSupport = "no";
      };
    })
  ];

  # Dotfiles.
  # nixpkgs.overlays = mkAfter [
  #   (import <dotfiles/nixpkgs/overlays/20-trivial-overrides.nix>)
  #   (import <dotfiles/nixpkgs/overlays/50-trivial-packages.nix>)
  # ];

  services.chunkwm.package = pkgs.chunkwm;
  services.chunkwm.hotload = false;
  services.chunkwm.plugins.dir = "${lib.getOutput "out" pkgs.chunkwm}/lib/chunkwm/plugins";
  services.chunkwm.plugins.list = [ "ffm" "tiling" ];
  services.chunkwm.plugins."tiling".config = ''
    chunkc set global_desktop_mode   bsp
  '';

  # Dotfiles.
  # services.chunkwm.extraConfig = builtins.readFile <dotfiles/chunkwm/chunkwmrc>;
  # services.skhd.skhdConfig = builtins.readFile <dotfiles/skhd/skhdrc>;

  # TODO: add module for per-user config, etc, ...
  # environment.etc."per-user/lnl/gitconfig".text = builtins.readFile <dotfiles/git/gitconfig>;
  system.activationScripts.extraUserActivation.text = "ln -sfn /etc/per-user/lnl/gitconfig ~/.gitconfig";

  users.nix.configureBuildUsers = true;
  users.nix.nrBuildUsers = 32;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 1;
}
