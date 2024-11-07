{ pkgsFunc ? import <nixpkgs>
, localSystem ? { system = builtins.currentSystem; }
, pkgs ? pkgsFunc { inherit localSystem; }
, speculosPkgs ? pkgsFunc {
    inherit localSystem;
    crossSystem = {
      #isStatic = true;
      config = "armv6l-unknown-linux-gnueabihf";
    };
  }
, withVnc ? pkgs.stdenv.hostPlatform.isLinux
}:

rec {
  inherit pkgs speculosPkgs;
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

  launcher = speculosPkgs.callPackage ({ stdenv, cmake, ninja, perl, pkg-config, openssl, cmocka, blst }: stdenv.mkDerivation {
    name = "speculos";

    inherit src;
    dontStrip=true;

    cmakeFlags = [
      "-DCMAKE_SKIP_BUILD_RPATH=ON"
    ];

    nativeBuildInputs = [
      cmake
      ninja
      perl
      pkg-config
    ];

    buildInputs = [
      (openssl.override (old: {
        # Need this so speculos can grab internal functions.
        static = true;
      }))
      cmocka
      (blst.overrideAttrs (old: {
        # TODO: find a better way to specify -Wno-error
        postUnpack = "sed -i 's/-Werror//; s/-all_load//;' source/build.sh";
      }))
    ];
  }) {
    openssl = speculosPkgs.openssl_1_1;
  };

  vnc_server = pkgs.callPackage ./src/vnc {
    inherit mkCleanSrc;
  };

  speculos = pkgs.python3Packages.callPackage (
  { buildPythonApplication, python3, qemu, makeWrapper
  , pyqt5, construct, mnemonic, pyelftools, setuptools, jsonschema, flask, flask-restful, pillow, requests, pytesseract
  , pytest, pytest-cov, setuptools_scm
  }: buildPythonApplication {
    pname = "speculos";
    version = "0.5.0";
    pyproject = true;

    inherit src ledgered;

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
      pytesseract
      ledgered

      qemu
    ];

    nativeBuildInputs = [ setuptools_scm ];
    SETUPTOOLS_SCM_PRETEND_VERSION = "0.5.0";

    doCheck = false;
    checkInputs = [
      pytest
      pytest-cov
    ];
  }) {};

  ledgered = pkgs.python3Packages.callPackage (
  { lib
  , buildPythonPackage
  , fetchPypi
  , setuptools
  , setuptools_scm
  , toml
  , pyelftools
  , pygithub
  }:

  buildPythonPackage rec {
    pname = "ledgered";
    version = "0.7.1";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Wyn5LzvZTIP6nWxrS+u62YNO24GmLTyr1HpnFAnNJdQ=";
    };

    build-system = [
      setuptools
      setuptools_scm
    ];

    propagatedBuildInputs = [
      setuptools
      setuptools_scm
      toml
      pyelftools
      pygithub
    ];

    doCheck = true;
  }) {};
}
