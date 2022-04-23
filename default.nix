{ pkgsFunc ? import <nixpkgs>
, localSystem ? { system = builtins.currentSystem; }
, pkgs ? pkgsFunc { inherit localSystem; }
, speculosPkgs ? pkgsFunc {
    inherit localSystem;
    crossSystem = {
      isStatic = true;
      config = "armv6l-unknown-linux-gnueabihf";
    };
  }
, withVnc ? pkgs.stdenv.hostPlatform.isLinux
}:

rec {
  inherit (pkgs) lib;

  mkCleanSrc = src: lib.cleanSourceWith {
    filter = path: type: let
        baseName = baseNameOf path;
      in !(builtins.any (x: x == baseName) [
        "result" ".git" "tags" "TAGS" "dist"
      ] || lib.hasPrefix "result" baseName
        || lib.hasSuffix ".nix" baseName);
    inherit src;
  };

  src = mkCleanSrc ./.;

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

  vnc_server = pkgs.callPackage ./src/vnc {
    inherit mkCleanSrc;
  };

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
	'' + lib.optionalString withVnc ''
      ln -s ${vnc_server}/bin/vnc_server "$resources_dir/vnc_server"
    '' + ''
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
  }) {};

}
