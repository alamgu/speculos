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
    filter = path: type: !(builtins.any (x: x == baseNameOf path) [
      "default.nix" "result" ".git" "tags" "TAGS" "dist"
    ]);
    src = ./.;
  };

  speculosLauncher = speculosPkgs.callPackage ({ stdenv, cmake, ninja, perl, pkg-config, openssl, cmocka }: stdenv.mkDerivation {
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

    installPhase = ''
      mkdir $out
      cp -a $cmakeDir/build/src/launcher $out/
    '';

    makeFlags = [ "emu" "launcher" ];
  }) {};

  speculos = pkgs.callPackage ({ stdenv, python3, qemu, makeWrapper }: stdenv.mkDerivation {
    name = "speculos";
    inherit src;
    buildPhase = "";
    nativeBuildInputs = [ makeWrapper ];
    buildInputs = [
      (python3.withPackages (ps: with ps; [
        pyqt5
        construct
        mnemonic
        pyelftools
        setuptools
        jsonschema
      ]))
      qemu
    ];
    installPhase = ''
    mkdir $out
    cp -a $src/speculos.py $out/
    install -d $out/bin
    ln -s $out/speculos.py $out/bin/speculos.py
    cp -a $src/mcu $out/mcu
    install -d $out/build/src/
    ln -s ${speculosLauncher}/launcher $out/build/src/launcher
    makeWrapper $out/speculos.py $out/bin/speculos --set PATH $PATH
    '';
  }) {};

}
