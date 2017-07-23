#! /usr/bin/env bash
set -o pipefail

{ # Prevent execution if this script was only partially downloaded


# Argument parsing
init(){
    if [ $# -gt 0 ]; then
        case "$1" in
            -h|--help)
                usage
                exit 1
                ;;
            -u|--create-daemon-users)
                export CREATE_DAEMON_USERS=true
                ;;
            *)
                echo -e "ERROR: Unrecognized parameter: '${1}'\nSee usage (--help) for options..." 1>&2
                exit 1
                ;;
        esac
    fi
}

# Usage
usage(){
    cat <<EOF
 Usage: bootstrap.sh [Options]

 Options:

   -h, --help: Show this message
   -u, --create-daemon-users: Create users & group for use with the Nix daemon
EOF
}


# Sanity checks
sanity(){
    # Ensure the script is running on macOS
    if [ $(uname -s) != "Darwin" ]; then
        echo "This script is for use with macOS!"
        exit 1
    fi

    # Ensure script is not being run with root privileges
    if [ $EUID -eq 0 ]; then
        echo "Please don't run this script with root privileges!"
        exit 1
    fi

    # Ensure Nix has already been installed
    if [[ ! $(type nix-env 2>/dev/null) ]]; then
        echo -e "Cannot find "$YELLOW"nix-env"$ESC" in the PATH"
        echo "Please ensure you've installed and configured your Nix environment correctly"
        echo -e "Install instructions can be found at: "$BLUE_UL"https://nixos.org/nix/manual/#chap-quick-start"$ESC""
        exit 1
    fi

    # Check if nix-darwin is already present
    if [[ $(type darwin-rebuild 2>/dev/null) ]]; then
        echo -e "It looks like "$YELLOW"nix-darwin"$ESC" is already installed..."
        [ ! -z $CREATE_DAEMON_USERS ] && create_daemon_users || exit 1
    fi
}

# Exit with message
exit_message(){
    echo -e ""$RED"$1"$ESC"" >&2
    exit 1
}

# Prompt for  sudo password & keep alive
sudo_prompt(){
  echo "Please enter your password for sudo authentication"
  sudo -k
  sudo echo "sudo authenticaion successful!"
  while true ; do sudo -n true ; sleep 60 ; kill -0 "$$" || exit ; done 2>/dev/null &
}

# Daemon setup
create_daemon_users(){
    echo -e ""$BLUE"Nix daemon user/group configuration"$ESC""
    [ ! -z $CREATE_DAEMON_USERS ] && sudo_prompt

    # If the group exists, dscl returns exit code 56.
    # Since this is not strictly an error code, standard code
    # checking doesn't work as intended.
    /usr/bin/dscl . -read /Groups/nixbld &> /dev/null
    retCode=$?
    if [[ $retCode != 0 ]]; then
        echo -e "Creating the "$YELLOW"nixbld"$ESC" group..."
        sudo /usr/sbin/dseditgroup -o create -r "Nix build group for nix-daemon" -i 30000 nixbld >&2 || \
            exit_message "Problem creating group: nixbld"
    else
        echo -e "It looks like the "$YELLOW"nixbld"$ESC" group already exists!"
    fi

    for i in {1..10}; do
        /usr/bin/id nixbld${i} &> /dev/null
        retCode=$?
        if [[ $retCode != 0 ]]; then
            echo -e "Creating user: "$YELLOW"nixbld${i}"$ESC"..."
            sudo /usr/sbin/sysadminctl -fullName "Nix build user $i" \
                -home /var/empty \
                -UID $(expr 30000 + $i) \
                -addUser nixbld$i >&2 \
                || exit_message "Problem creating user: nixbld${i}"

            sudo dscl . -create /Users/nixbld$i IsHidden 1 || \
                exit_message "Problem setting 'IsHidden' for user: nixbld${i}"
            sudo dscl . -create /Users/nixbld$i UserShell /sbin/nologin || \
                exit_message "Problem setting shell for user: nixbld${i}"
            sudo /usr/sbin/dseditgroup -o edit -t user -a nixbld$i nixbld || \
                exit_message "Problem setting primary group for user: nixbld${i}"
            sudo /usr/bin/dscl . -create /Users/nixbld$i PrimaryGroupID 30000 >&2 || \
                exit_message "Problem setting PrimaryGroupID for user: nixbld${i}"
        else
            echo -e "It looks like the "$YELLOW"nixbld${i}"$ESC" user already exists!"
        fi
    done

    [ ! -z $CREATE_DAEMON_USERS ] && exit 0
}

# Installer
install(){
    echo -e ""$BLUE_UL"Welcome to the nix-darwin installer!"$ESC""

    # Prompt for nix package upgrade
    echo -e "Ensuring "$YELLOW"nixpkgs"$ESC" version meets requirements..."
    echo -e "To do this, the following will be run to upgrade the "$YELLOW"nix"$ESC" package:"
    echo -e ""$YELLOW"nix-env -iA nixpkgs.nix"$ESC"\n"
    echo "If you have a recent install of Nix, this may not be necessary, but should not cause any harm to run"
    while true ; do
        read -p "Would you like to upgrade? [y/n] " ANSWER
        case $ANSWER in
            y|Y)
                echo "Proceeding with upgrade..."
                nix-env -iA nixpkgs.nix || exit
                break
                ;;
            n|N)
                echo "Proceeding without upgrade..."
                break
                ;;
            *)
                echo "Please answer 'y' or 'n'..."
        esac
    done

    sudo_prompt || exit

    # Link run directory
    echo "Setting up /run..."
    if ! test -L /run; then
      sudo ln -sfn private/var/run /run || exit
    fi

    # Fetch the nix-darwin repo
    echo -e ""$YELLOW"Configuring darwin channel..."$ESC""
    nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin || exit
    nix-channel --update || exit

    # Create symlink for old NIX_PATH entry
    ln -sfn "/nix/var/nix/profiles/per-user/$USER/channels/darwin" "$HOME/.nix-defexpr/darwin" || exit

    # Copy the example configuration
    echo -e "Copying example configuration to "$YELLOW"~/.nixpkgs/darwin-configuration.nix"$ESC"..."

    if [ ! -e "$HOME/.nixpkgs/darwin-configuration.nix" ]; then
      mkdir -p "$HOME/.nixpkgs" || exit
      cp "$HOME/.nix-defexpr/darwin/modules/examples/simple.nix" "$HOME/.nixpkgs/darwin-configuration.nix" || exit
      chmod u+w "$HOME/.nixpkgs/darwin-configuration.nix" || exit
    fi

    # Bootstrap build using default nix.nixPath
    echo "Bootstrapping..."
    export NIX_PATH=darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$NIX_PATH
    $(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild build || exit
    $(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild switch || exit

    # Source generated bashrc
    . /etc/static/bashrc

    # Run first darwin-rebuild switch
    echo -e "Running first "$YELLOW"darwin-rebuild switch"$ESC"..."
    darwin-rebuild switch && echo -e ""$GREEN"Success!"$ESC"" || exit_message "Problem running darwin-rebuild switch"

    echo -e ""$BLUE_UL"Nix daemon"$ESC""
    echo    "Optionally, this script can also create the group and users"
    echo -e "needed for running the Nix "$YELLOW"multi-user support daemon"$ESC"."
    echo    "If you're unfamiliar with the Nix daemon, see:"
    echo -e ""$BLUE_UL"http://nixos.org/nix/manual/#sec-nix-daemon\n"$ESC""
    echo    "If you decide not to, but later change your mind, you can always re-run"
    echo -e "this script with "$YELLOW"-u"$ESC" or "$YELLOW"--create-daemon-users"$ESC""

    while true ; do
        read -p "Would you like to create the Nix daemon group/users? [y/n] " ANSWER
        case $ANSWER in
            y|Y)
                create_daemon_users || exit
                break
                ;;
            n|N)
                echo "Not creating Nix daemon group/users"
                break
                ;;
            *)
                echo "Please answer 'y' or 'n'..."
        esac
    done

    # Finish
    echo -e ""$GREEN"You're all done!"$ESC""
    echo -e "Take a look at "$YELLOW"~/.nixpkgs/darwin-configuration.nix"$ESC" to get started."
    echo -e "See the README for more information: "$BLUE_UL"https://github.com/LnL7/nix-darwin/blob/master/README.md"$ESC""
}

main(){
    # ANSI properties/colours
    local ESC='\033[0m'
    local BLUE='\033[38;34m'
    local BLUE_UL='\033[38;4;34m'
    local GREEN='\033[38;32m'
    local GREEN_UL='\033[38;4;32m'
    local RED='\033[38;31m'
    local RED_UL='\033[38;4;31m'
    local YELLOW='\033[38;33m'
    local YELLOW_UL='\033[38;4;33m'

    init $@
    sanity
    install
}

# Actual run
main $@


} # Prevent execution if this script was only partially downloaded
