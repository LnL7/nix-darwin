{ stdenv
, Foundation
, fetchFromGitHub
, xcbuildHook
}:
let rev = "4bbfc25b485e444afcca8b9d5492ef0018c03823"; in
stdenv.mkDerivation {
  name = "xpc_set_event_stream_handler";
  version = builtins.substring 1 7 rev;

  src = fetchFromGitHub {
    owner = "snosrap";
    repo = "xpc_set_event_stream_handler";
    inherit rev;
    sha256 = "17vv5nacl56h59h3pmawab4cpk54xxg2cxvnijqid4lmvlz6nidq";
  };

  nativeBuildInputs = [
    xcbuildHook
    Foundation
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp Products/Release/xpc_set_event_stream_handler $out/bin
  '';

  meta = with stdenv.lib; {
    description = "Consume a com.apple.iokit.matching event, then run the executable specified in the first parameter.";
    homepage = https://github.com/snosrap/xpc_set_event_stream_handler;
    platforms = platforms.darwin;
    license = [ licenses.mit ];
    maintainers = [ maintainers.eqyiel ];
  };
}
