{ config, pkgs, ... }:

{
  services.caddy.enable = true;
  services.caddy.virtualHosts."http://foo.com:8000" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:9000
    '';
  };
  test = ''
    export PATH="$PATH:${pkgs.jq}/bin"
    plist=${config.out}/user/Library/LaunchAgents/org.nixos.caddy.plist
    test -f $plist
    grep -q '<string>exec /nix/store/.*/bin/caddy ' $plist
    config=$(grep -oP -- "--config \K(.*\.json)" $plist)

    listenAddress=$(jq '.apps.http.servers.srv0.listen | first' -r $config)
    domain=$(jq '.apps.http.servers.srv0.routes | first .match | first .host | first' -r $config)
    directive=$(jq '.apps.http.servers.srv0.routes | first | .handle | first | .routes | first | .handle | first | .handler' -r $config)
    proxyHost=$(jq '.apps.http.servers.srv0.routes | first | .handle | first | .routes | first | .handle | first | .upstreams | first | .dial' -r $config)

    if [[ "$listenAddress" != ":8000" ]]; then
      echo "Listen address should be 8000"
      exit 1
    fi

    if [[ "$domain" != "foo.com" ]]; then
      echo "Domain should be foo.com"
      exit 1
    fi

    if [[ "$proxyHost" != "127.0.0.1:9000" ]]; then
      echo "Domain should be 127.0.0.1:9000"
      exit 1
    fi
  '';
}
