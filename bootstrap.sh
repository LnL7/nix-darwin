#! /usr/bin/env bash
set -e
set -o pipefail

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
	exit 1
    fi
}

# Exit with message
exit_message(){
    echo -e ""$RED"$1"$ESC"" >&2
    exit 1
}

# Installer
install(){
    echo -e ""$BLUE"Welcome to the nix-darwin installer!"$ESC""

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
		nix-env -iA nixpkgs.nix
		break
		;;
	    n|N)
		echo "Proceeding without upgrading..."
		break
		;;
	    *)
		echo "Please answer 'y' or 'n'..."
	esac
    done

    # Prompt for initial sudo password & keep alive
    echo "Please enter your password for sudo authentication"
    sudo -k
    sudo echo "sudo authenticaion successful!"
    while true ; do sudo -n true ; sleep 60 ; kill -0 "$$" || exit ; done 2>/dev/null &


    # Link run directory
    echo "Setting up /run..."
    test -L /run || sudo ln -s /private/var/run /run

    # Fetch the nix-darwin repo as a zip (shouldn't assume presence of git)
    REPO_DOWNLOAD=/tmp/nix-darwin-$(date +%Y%m%d).zip
    if [ ! -f $REPO_DOWNLOAD ]; then
	echo -e ""$YELLOW"Fetching nix-darwin repo..."$ESC""
	curl -Lo $REPO_DOWNLOAD https://github.com/LnL7/nix-darwin/archive/master.zip || \
	    exit_message "Problem downloading nix-darwin repo"
    fi

    # Extract the repository
    echo -e "Extracting repo to "$YELLOW"~/.nix-defexpr/darwin"$ESC"..."
    mkdir -p ~/.nix-defexpr
    cd ~/.nix-defexpr
    unzip -q $REPO_DOWNLOAD && echo -e ""$GREEN"Success!"$ESC""
    mv nix-darwin-master darwin
    cd - &> /dev/null

    # Copy the example configuration
    echo -e "Copying example configuration to "$YELLOW"~/.nixpkgs/darwin-configuration.nix"$ESC"..."
    mkdir -p ~/.nixpkgs
    cp ~/.nix-defexpr/darwin/modules/examples/simple.nix ~/.nixpkgs/darwin-configuration.nix

    # Bootstrap build using default nix.nixPath
    echo "Bootstrapping..."
    export NIX_PATH=darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$NIX_PATH
    $(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild build
    $(nix-build '<darwin>' -A system --no-out-link)/sw/bin/darwin-rebuild switch

    # Source generated bashrc
    . /etc/static/bashrc

    # Run first darwin-rebuild switch
    echo -e "Running first "$YELLOW"darwin-rebuild switch"$ESC"..."
    darwin-rebuild switch && echo -e ""$GREEN"Success!"$ESC"" || exit_message "Problem running darwin-rebuild switch"

    echo -e ""$BLUE"You're all done!"$ESC""
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

    sanity
    install
}

# Actual run
main
