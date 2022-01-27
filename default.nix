{ pkgsFunc ? import <nixpkgs>
, pkgs ? pkgsFunc {}
, speculosPkgs ? pkgsFunc {
    crossSystem = {
      isStatic = true;
      config = "armv6l-unknown-linux-gnueabihf";
    };
  }
}:

rec {
  inherit (pkgs) lib;

  src = lib.cleanSourceWith {
    filter = path: type: let
        baseName = baseNameOf path;
      in !(builtins.any (x: x == baseName) [
        "result" ".git" "tags" "TAGS" "dist"
      ] || lib.hasPrefix "result" baseName
        || lib.hasSuffix ".nix" baseName);
    src = ./.;
  };

  launcher = speculosPkgs.callPackage ({ stdenv, cmake, ninja, perl, pkg-config, openssl, cmocka }: stdenv.mkDerivation {
    name = "speculos";

    inherit src;

    nativeBuildInputs = [
      cmake
      ninja
      perl
      pkg-config
    ];

    buildInputs = [
      openssl
      cmocka
    ];
  }) {};

  vnc_server = pkgs.callPackage ({ stdenv, cmake, ninja, pkg-config, libvncserver }: stdenv.mkDerivation {
    name = "vnc_server";

    src = "${src}/src/vnc";

    nativeBuildInputs = [
      cmake
      ninja
      pkg-config
    ];

    buildInputs = [
      libvncserver
    ];

    strictDeps = true;
  }) {};

  speculos = pkgs.python3Packages.callPackage (
  { buildPythonApplication, python3, qemu, makeWrapper 
  , pyqt5, construct, mnemonic, pyelftools, setuptools, jsonschema, flask, flask-restful, pillow, requests 
  , pytest
  }: buildPythonApplication {
    pname = "speculos";
    version = "git";

    inherit src;

    postUnpack = ''
      rm $sourceRoot/README.md
      cp -f ${./README.md} $sourceRoot/README.md
      resources_dir=$sourceRoot/speculos/resources/
      mkdir -p "$resources_dir"
	  ln -s ${launcher}/bin/launcher "$resources_dir/launcher"
      ln -s ${vnc_server}/bin/vnc_server "$resources_dir/vnc_server"
      install -d $out/bin/
      cp ${src}/tools/debug.sh "$out/bin/"
      cp ${src}/tools/gdbinit "$out/bin/"
    '';

    postPatch = ''
      substituteInPlace setup.py \
        --replace "flask>=2.0.0,<3.0.0" "flask"
    '';

    propagatedBuildInputs = [
      pyqt5
      construct
      mnemonic
      pyelftools
      setuptools
      jsonschema
      flask
      flask-restful
      pillow
      requests

      qemu
    ];

    checkInputs = [
      pytest
    ];

    #installPhase = ''
    #  mkdir $out
    #  cp -a $src/speculos.py $out/
    #  install -d $out/bin
    #  cp -a $src/mcu $out/mcu
    #  cp -a api $out/api
    #  install -d $out/libexec
    #  ln -s ${speculosLauncher}/bin/launcher $out/libexec/launcher
    #  install -d $out/cxlib
    #  ln -s ${speculos/cxlib/cx-2.0.elf} $out/cxlib/cx-2.0.elf
    #  makeWrapper $out/speculos.py $out/bin/speculos --set PATH $PATH
    #'';
  }) {};

}
