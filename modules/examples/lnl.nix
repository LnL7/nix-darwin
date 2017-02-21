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

  environment.extraOutputsToInstall = [ "man" ];

  services.khd.enable = true;
  services.kwm.enable = true;

  launchd.user.agents.fetch-nixpkgs = {
    command = "${pkgs.git}/bin/git -C ~/.nix-defexpr/nixpkgs fetch origin master";
    environment.GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    serviceConfig.KeepAlive = false;
    serviceConfig.ProcessType = "Background";
    serviceConfig.StartInterval = 60;
  };

  services.activate-system.enable = true;
  services.nix-daemon.enable = true;
  services.nix-daemon.tempDir = "/nix/tmp";

  # nix.distributedBuilds = true;
  nix.extraOptions = "pre-build-hook = ";

  nix.binaryCachePublicKeys = [ "cache.daiderd.com-1:R8KOWZ8lDaLojqD+v9dzXAqGn29gEzPTTbr/GIpCTrI=" ];
  nix.trustedBinaryCaches = [ http://cache1 https://cache.daiderd.com ];

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
    { names = [ "fzfWrapper" "youcompleteme" "syntastic" "gist-vim" "webapi-vim" "vim-eunuch" "vim-repeat" "commentary" "polyglot" "colors-solarized" ]; }
  ];

  programs.vim.vimConfig =  ''
    colorscheme solarized
    set bg=dark

    set clipboard=unnamed

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

    vmap s S

    cnoremap %% <C-r>=expand('%:h') . '/'<CR>

    let mapleader = ' '
    nnoremap <Leader>p :FZF<CR>
    nnoremap <silent> <Leader>e :exe 'FZF ' . expand('%:h')<CR>

    function! s:ag_to_qf(line)
      let parts = split(a:line, ':')
      return {'filename': parts[0], 'lnum': parts[1], 'col': parts[2],
            \ 'text': join(parts[3:], ':')}
    endfunction

    function! s:ag_handler(lines)
      if len(a:lines) < 2 | return | endif

      let cmd = get({'ctrl-x': 'split',
            \ 'ctrl-v': 'vertical split',
            \ 'ctrl-t': 'tabe'}, a:lines[0], 'e')
      let list = map(a:lines[1:], 's:ag_to_qf(v:val)')

      let first = list[0]
      execute cmd escape(first.filename, ' %#\')
      execute first.lnum
      execute 'normal!' first.col.'|zz'

      if len(list) > 1
        call setqflist(list)
        copen
        wincmd p
      endif
    endfunction

    command! -nargs=* Ag call fzf#run({
          \ 'source':  printf('${pkgs.ag}/bin/ag --nogroup --column --color "%s"',
          \                   escape(empty(<q-args>) ? '^(?=.)' : <q-args>, '"\')),
          \ 'sink*':   function('<sid>ag_handler'),
          \ 'options': '--ansi --expect=ctrl-t,ctrl-v,ctrl-x --delimiter : --nth 4.. '.
          \            '--multi --bind ctrl-a:select-all,ctrl-d:deselect-all '.
          \            '--color hl:68,hl+:110',
          \ 'down':    '50%' })

    let g:syntastic_always_populate_loc_list = 1
    let g:ycm_seed_identifiers_with_syntax = 1
  '';

  programs.zsh.enable = true;
  programs.zsh.enableBashCompletion = true;
  programs.zsh.enableFzfCompletion = true;
  programs.zsh.enableFzfGit = true;
  programs.zsh.enableFzfHistory = true;

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
    setopt AUTOCD AUTOPUSHD

    autoload -U down-line-or-beginning-search
    autoload -U up-line-or-beginning-search
    bindkey '^[[A' down-line-or-beginning-search
    bindkey '^[[A' up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    zle -N up-line-or-beginning-search
  '';

  environment.variables.HOMEBREW_CASK_OPTS = "--appdir=/Applications/cask";

  environment.shellAliases.l = "ls -lh";
  environment.shellAliases.ls = "ls -G";
  environment.shellAliases.g = "git log --pretty=color -32";
  environment.shellAliases.gl = "git log --pretty=color --graph";
  environment.shellAliases.glog = "git log --pretty=nocolor";
  environment.shellAliases.gd = "git diff --minimal --patch";

  nix.nixPath =
    [ # Use local nixpkgs checkout instead of channels.
      "darwin=$HOME/.nix-defexpr/darwin"
      "darwin-config=$HOME/.nixpkgs/darwin-configuration.nix"
      "nixpkgs=$HOME/.nix-defexpr/nixpkgs"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: { };

  # TODO: add module for per-user config, etc, ...
  environment.etc."per-user/lnl/gitconfig".text = ''
    [include]
      path = .gitconfig.local

    [core]
      excludesfile = ~/.gitignore
      autocrlf     = input

    [color]
      ui = auto

    [pretty]
      color = format:%C(yellow)%h%Cblue%d%Creset %s %C(white)  %an, %ar%Creset
      nocolor = format:%h%d %s   %an, %ar

    [user]
      name = Daiderd Jordan

    [github]
      user = LnL7
  '';

  environment.etc."per-user/lnl/khdrc".text = ''
    # remap left-control h/j/k/l -> arrow keys
    lctrl - h         [Safari]      :   khd -p "- left"
    lctrl - j         [Safari]      :   khd -p "- down"
    lctrl - k         [Safari]      :   khd -p "- up"
    lctrl - l         [Safari]      :   khd -p "- right"

    shift + lctrl - h [Safari]      :   khd -p "shift - left"
    shift + lctrl - j [Safari]      :   khd -p "shift - down"
    shift + lctrl - k [Safari]      :   khd -p "shift - up"
    shift + lctrl - l [Safari]      :   khd -p "shift - right"

    # remap left-control a / e   -> start / end of line
    lctrl - a         [Safari]      :   khd -p "cmd - left"
    lctrl - e         [Safari]      :   khd -p "cmd - right"

    shift + lctrl - e [Safari]      :   khd -p "shift + cmd - left"
    shift + lctrl - e [Safari]      :   khd -p "shift + cmd - right"

    # remap left-control b / w   -> start / end of word
    lctrl - b         [Safari]      :   khd -p "alt - left"
    lctrl - w         [Safari]      :   khd -p "alt - right"

    shift + lctrl - b [Safari]      :   khd -p "shift + alt - left"
    shift + lctrl - w [Safari]      :   khd -p "shift + alt - right"

    # remap left-control u / d   -> page up / page down
    lctrl - u         [Safari]      :   khd -p "alt - up"
    lctrl - d         [Safari]      :   khd -p "alt - down"

    shift + lctrl - u [Safari]      :   khd -p "shift + alt - up"
    shift + lctrl - d [Safari]      :   khd -p "shift + alt - down"

    # remap left-control x       -> forward delete
    lctrl - x         [Safari]      :   khd -p "- delete"

    # remap left-control g       -> escape
    lctrl - g         [Safari]      :   khd -p "0x35"


    # modifier only mappings
    khd mod_trigger_timeout 0.2
    lctrl    :   khd -p "0x35"
    lshift   :   khd -p "shift - 9"
    rshift   :   khd -p "shift - 0"


    # enable kwm compatibility mode
    khd kwm on


    # set border color for different modes
    # khd mode default color 0xddd5c4a1
    khd mode default color 0x00000000
    khd mode switcher color 0xddbdd322
    khd mode scratchpad color 0xddd75f5f
    khd mode swap color 0xdd458588
    khd mode tree color 0xddfabd2f
    khd mode space color 0xddb16286
    khd mode info color 0xddcd950c


    # toggle between modes
    alt - f                 :   khd -e "mode activate switcher"
    switcher + alt - f      :   khd -e "mode activate default"
    swap + alt - f          :   khd -e "mode activate switcher"
    space + alt - f         :   khd -e "mode activate switcher"
    tree + alt - f          :   khd -e "mode activate switcher"
    info + alt - f          :   khd -e "mode activate switcher"
    scratchpad + alt - f    :   khd -e "mode activate switcher"

    switcher + alt - g      :   khd -e "mode activate default"
    swap + alt - g          :   khd -e "mode activate default"
    space + alt - g         :   khd -e "mode activate default"
    tree + alt - g          :   khd -e "mode activate default"
    info + alt - g          :   khd -e "mode activate default"
    scratchpad + alt - g    :   khd -e "mode activate default"
    switcher + ctrl - g     :   khd -e "mode activate default"
    swap + ctrl - g         :   khd -e "mode activate default"
    space + ctrl - g        :   khd -e "mode activate default"
    tree + ctrl - g         :   khd -e "mode activate default"
    info + ctrl - g         :   khd -e "mode activate default"
    scratchpad + ctrl - g   :   khd -e "mode activate default"
    switcher - 0x35         :   khd -e "mode activate default"
    swap - 0x35             :   khd -e "mode activate default"
    space - 0x35            :   khd -e "mode activate default"
    tree - 0x35             :   khd -e "mode activate default"
    info - 0x35             :   khd -e "mode activate default"
    scratchpad - 0x35       :   khd -e "mode activate default"

    switcher - w            :   khd -e "mode activate scratchpad"
    switcher - a            :   khd -e "mode activate swap"
    switcher - s            :   khd -e "mode activate space"
    switcher - d            :   khd -e "mode activate tree"
    switcher - q            :   khd -e "mode activate info"


    # switcher mode
    switcher - r            :   khd -e "reload" # reload config

    switcher - return       :   open -na /Applications/Utilities/Terminal.app;\
                                khd -e "mode activate default"

    switcher - h            :   kwmc window -f west
    switcher - l            :   kwmc window -f east
    switcher - j            :   kwmc window -f south
    switcher - k            :   kwmc window -f north
    switcher - n            :   kwmc window -fm prev
    switcher - m            :   kwmc window -fm next

    switcher - 1            :   kwmc space -fExperimental 1
    switcher - 2            :   kwmc space -fExperimental 2
    switcher - 3            :   kwmc space -fExperimental 3
    switcher - 4            :   kwmc space -fExperimental 4
    switcher - 5            :   kwmc space -fExperimental 5
    switcher - 6            :   kwmc space -fExperimental 6

    switcher - z            :   kwmc space -fExperimental left
    switcher - c            :   kwmc space -fExperimental right
    switcher - f            :   kwmc space -fExperimental previous

    switcher + shift - z    :   kwmc window -m space left;\
                                kwmc space -fExperimental left

    switcher + shift - c    :   kwmc window -m space right;\
                                kwmc space -fExperimental right

    switcher + shift - 1    :   kwmc display -f 0
    switcher + shift - 2    :   kwmc display -f 1
    switcher + shift - 3    :   kwmc display -f 2


    scratchpad - a          :   kwmc scratchpad add
    scratchpad - s          :   kwmc scratchpad toggle 0
    scratchpad - d          :   kwmc scratchpad remove

    scratchpad - 1          :   kwmc scratchpad toggle 1
    scratchpad - 2          :   kwmc scratchpad toggle 2
    scratchpad - 3          :   kwmc scratchpad toggle 3
    scratchpad - 4          :   kwmc scratchpad toggle 4
    scratchpad - 5          :   kwmc scratchpad toggle 5
    scratchpad - 6          :   kwmc scratchpad toggle 6


    # swap mode
    swap - h                :   kwmc window -s west
    swap - j                :   kwmc window -s south
    swap - k                :   kwmc window -s north
    swap - l                :   kwmc window -s east
    swap - m                :   kwmc window -s mark

    swap + shift - k        :   kwmc window -m north
    swap + shift - l        :   kwmc window -m east
    swap + shift - j        :   kwmc window -m south
    swap + shift - h        :   kwmc window -m west
    swap + shift - m        :   kwmc window -m mark

    swap - 1                :   kwmc window -m space 1
    swap - 2                :   kwmc window -m space 2
    swap - 3                :   kwmc window -m space 3
    swap - 4                :   kwmc window -m space 4
    swap - 5                :   kwmc window -m space 5

    swap - z                :   kwmc window -m space left
    swap - c                :   kwmc window -m space right

    swap + shift - 1        :   kwmc window -m display 0
    swap + shift - 2        :   kwmc window -m display 1
    swap + shift - 3        :   kwmc window -m display 2


    # space mode
    space - a               :   kwmc space -t bsp
    space - s               :   kwmc space -t monocle
    space - d               :   kwmc space -t float

    space - x               :   kwmc space -g increase horizontal
    space - y               :   kwmc space -g increase vertical

    space + shift - x       :   kwmc space -g decrease horizontal
    space + shift - y       :   kwmc space -g decrease vertical

    space - left            :   kwmc space -p increase left
    space - right           :   kwmc space -p increase right
    space - up              :   kwmc space -p increase top
    space - down            :   kwmc space -p increase bottom
    space - p               :   kwmc space -p increase all

    space + shift - left    :   kwmc space -p decrease left
    space + shift - right   :   kwmc space -p decrease right
    space + shift - up      :   kwmc space -p decrease top
    space + shift - down    :   kwmc space -p decrease bottom
    space + shift - p       :   kwmc space -p decrease all


    # tree mode
    tree - a                :   kwmc window -c type bsp
    tree - s                :   kwmc window -c type monocle
    tree - f                :   kwmc window -z fullscreen
    tree - d                :   kwmc window -z parent
    tree - w                :   kwmc window -t focused
    tree - r                :   kwmc tree rotate 90

    tree - q                :   kwmc window -c split - mode toggle;\
                                khd -e "mode activate default"

    tree - c                :   kwmc window -c type toggle;\
                                khd -e "mode activate default"

    tree - h                :   kwmc window -c expand 0.05 west
    tree - j                :   kwmc window -c expand 0.05 south
    tree - k                :   kwmc window -c expand 0.05 north
    tree - l                :   kwmc window -c expand 0.05 east
    tree + shift - h        :   kwmc window -c reduce 0.05 west
    tree + shift - j        :   kwmc window -c reduce 0.05 south
    tree + shift - k        :   kwmc window -c reduce 0.05 north
    tree + shift - l        :   kwmc window -c reduce 0.05 east

    tree - p                :   kwmc tree -pseudo create
    tree + shift - p        :   kwmc tree -pseudo destroy

    tree - o                :   kwmc window -s prev
    tree + shift - o        :   kwmc window -s next
  '';

  environment.etc."per-user/lnl/kwm/kwmrc".text = ''
    kwmc config tiling bsp
    kwmc config split-ratio 0.5
    kwmc config spawn left


    kwmc config padding 28 2 2 2
    kwmc config gap 2 2
    kwmc config display 1 padding 40 20 20 20
    kwmc config display 1 gap 10 10
    kwmc config display 2 padding 40 20 20 20
    kwmc config display 2 gap 10 10

    kwmc config space 0 1 name main
    kwmc config space 0 2 name rnd
    kwmc config space 0 3 mode monocle
    kwmc config space 0 3 name web
    kwmc config space 1 1 name rnd
    kwmc config space 1 1 mode monocle
    kwmc config space 2 1 name web


    kwmc config focus-follows-mouse on
    kwmc config mouse-follows-focus on
    kwmc config standby-on-float on
    kwmc config center-on-float on
    kwmc config float-non-resizable on
    kwmc config lock-to-container on
    kwmc config cycle-focus on
    kwmc config optimal-ratio 1.605

    kwmc config border focused on
    kwmc config border focused size 2
    kwmc config border focused color 0x00000000
    kwmc config border focused radius 6

    kwmc config border marked on
    kwmc config border marked size 2
    kwmc config border marked color 0xDD7f7f7f
    kwmc config border marked radius 6

    kwmc rule owner="iTerm2" properties={role="AXDialog"}

    kwmc rule owner="Airmail" properties={float="true"}
    kwmc rule owner="Apple Store" properties={float="true"}
    kwmc rule owner="System Preferences" properties={float="true"}
    kwmc rule owner="iTunes" properties={float="true"}
  '';
}
