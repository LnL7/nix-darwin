{ darwin }:

let
  inherit (darwin) config;
in {
  inherit (config.system.build) darwin-option darwin-rebuild;
}
