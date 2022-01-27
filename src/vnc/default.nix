{ stdenv, cmake, ninja, pkg-config, libvncserver
, mkCleanSrc
}:

stdenv.mkDerivation {
  name = "vnc_server";

  src = mkCleanSrc ./.;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    libvncserver
  ];

  strictDeps = true;
}
