{ stdenv, sourceProg, debug ? false }:
# For testing:
# $ nix-build -E 'with import <nixpkgs> {}; pkgs.callPackage ./wrapper.nix { sourceProg = "${pkgs.hello}/bin/hello"; debug = true; }'
stdenv.mkDerivation {
  name = "security-wrapper-${baseNameOf sourceProg}";
  dontUnpack = true;
  CFLAGS = [
    ''-DSOURCE_PROG="${sourceProg}"''
  ] ++ (if debug then [
    "-Werror" "-Og" "-g"
  ] else [
    "-Wall" "-O2"
  ]);
  dontStrip = debug;
  installPhase = ''
    mkdir -p $out/bin
    $CC $CFLAGS ${./wrapper.c} -o $out/bin/security-wrapper
  '';
}
