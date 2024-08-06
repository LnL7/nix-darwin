{ stdenv, fetchurl }:

stdenv.mkDerivation (finalAttrs: {
  pname = "nix-installer";
  version = "0.15.1";

  src = fetchurl {
    url = "https://github.com/DeterminateSystems/${finalAttrs.pname}/releases/download/v${finalAttrs.version}/${finalAttrs.pname}-aarch64-darwin";
    hash = "sha256-mcYiRv1KD7F83MJTaV4++dXroPBjelvbGYeSM0Lzdc8=";
  };

  dontUnpack = true;

  installPhase = "install -Dm555 $src $out/bin/${finalAttrs.pname}";

  meta.mainProgram = finalAttrs.pname;
})
