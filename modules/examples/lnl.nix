{ config, lib, pkgs, ... }:
{
  system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 10;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
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

  environment.systemPackages =
    [ pkgs.curl
      pkgs.fzf
      pkgs.gettext
      pkgs.git
      pkgs.jq
      pkgs.mosh
      pkgs.silver-searcher

      pkgs.nix-repl
      pkgs.nox
    ];

  services.nix-daemon.enable = true;
  services.nix-daemon.tempDir = "/nix/tmp";

  services.activate-system.enable = true;

  programs.nix-script.enable = true;

  programs.tmux.enable = true;
  programs.tmux.enableSensible = true;
  programs.tmux.enableMouse = true;
  programs.tmux.enableFzf = true;
  programs.tmux.enableVim = true;

  programs.tmux.tmuxConfig = ''
    bind 0 set status

    set -g status-bg black
    set -g status-fg white
  '';

  programs.vim.enable = true;
  programs.vim.enableSensible = true;

  programs.vim.plugins = [
    { names = [ "fzfWrapper" "youcompleteme" "colors-solarized" ]; }
  ];

  programs.vim.vimConfig =  ''
    colorscheme solarized
    set bg=dark

    set clipboard=unnamed

    vmap s S

    cnoremap %% <C-r>=expand('%:h') . '/'<CR>

    let mapleader = ' '
    nnoremap <Leader>p :FZF<CR>
    nnoremap <silent> <Leader>e :exe 'FZF ' . expand('%:h')<CR>

    set backup
    set backupdir=~/.vim/tmp/backup//
    set backupskip=/tmp/*,/private/tmp/*
    set directory=~/.vim/tmp/swap/
    set noswapfile
    set undodir=~/.vim/tmp/undo//
    set undofile

    if !isdirectory(expand(&undodir))
      call mkdir(expand(&undodir), "p")
    endif
    if !isdirectory(expand(&backupdir))
      call mkdir(expand(&backupdir), "p")
    endif
    if !isdirectory(expand(&directory))
      call mkdir(expand(&directory), "p")
    endif
  '';

  programs.zsh.enable = true;
  programs.zsh.enableBashCompletion = true;

  programs.zsh.variables.cfg = "$HOME/.nixpkgs/darwin-config.nix";
  programs.zsh.variables.darwin = "$HOME/.nix-defexpr/darwin";
  programs.zsh.variables.pkgs = "$HOME/.nix-defexpr/nixpkgs";


  programs.zsh.promptInit = ''
    autoload -U promptinit && promptinit

    PROMPT='%B%(?..%? )%b⇒ '
    RPROMPT='%F{green}%~%f'
  '';

  programs.zsh.loginShellInit = ''
    reexec() {
      echo "reexecuting shell: $SHELL" >&2
      __ETC_ZSHRC_SOURCED= \
      __ETC_ZSHENV_SOURCED= \
      __ETC_ZPROFILE_SOURCED= \
        exec $SHELL -l
    }
  '';

  programs.zsh.interactiveShellInit = ''
    bindkey -e
    setopt AUTOCD
  '';

  environment.variables.HOMEBREW_CASK_OPTS = "--appdir=/Applications/cask";

  environment.variables.GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  environment.variables.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  environment.shellAliases.l = "ls -lh";
  environment.shellAliases.ls = "ls -G";
  environment.shellAliases.g = "git log  --oneline --max-count 42";
  environment.shellAliases.gl = "git log --graph --oneline";
  environment.shellAliases.gd = "git diff --minimal --patch";

  # environment.shellAliases.nix = "${pkgs.lnl.nix-script}/bin/nix";

  nix.nixPath =
    [ # Use local nixpkgs checkout instead of channels.
      "darwin=$HOME/.nix-defexpr/darwin"
      "darwin-config=$HOME/.nixpkgs/darwin-configuration.nix"
      "nixpkgs=$HOME/.nix-defexpr/nixpkgs"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
  };
}
