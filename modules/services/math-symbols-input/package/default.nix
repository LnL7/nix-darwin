{ stdenv, fetchurl, xar, zip, cpio }:

let
  patch = fetchurl {
    url =
      "https://github.com/knrafto/MathSymbolsInput/commit/19352edd3e181d7ff3030460b3a87bbbaef7bccc.patch";
    sha256 = "sha256-0q0PJE3ZxaIHof5o6epgncMtgrVBWBIm+CZbkfl1Z2E=";
  };

in stdenv.mkDerivation rec {
  pname = "MathSymbolsInput";
  version = "v1.2";

  src = fetchurl {
    url =
      "https://github.com/knrafto/${pname}/releases/download/${version}/${pname}.pkg";
    sha256 = "sha256-/zQ9PEP9qO6fc77PcWeHMJa7gICyJL6UmuoZPNezDVc=";
  };

  phases = [ "unpackPhase" "buildPhase" "installPhase" ];
  unpackPhase = "xar -xf $src";

  buildInputs = [ xar zip cpio ];

  buildPhase = ''
    cat MathSymbolsInput.pkg/Payload  | gunzip -dc | cpio -i
    patch -u Math\ Symbols\ Input.app/Contents/Resources/commands.txt -i ${patch}
  '';

  installPhase = ''
    mkdir -p $out
    cp -r "Math Symbols Input.app" $out
  '';
}
