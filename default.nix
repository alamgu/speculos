{ pkgs ? import ../nixpkgs {}, gitDescribe ? "TEST-dirty", nanoXSdk ? null, ... }:
rec {
  speculosPkgs = import pkgs.path {
    crossSystem = {
      config = "armv6l-unknown-linux-gnueabihf";
      #config = "armv6l-unknown-linux-musleabihf";
      #useLLVM = true;
      #platform = {
      #  gcc = {
      #    arch = "armv6t2";
      #    fpu = "vfpv2";
      #  };
      #};
    };
    config = { allowUnsupportedSystem = true; };
    overlays = [
      (self: super: rec {
        speculosLauncher = speculosPkgs.callPackage ({ stdenv, cmake, ninja, perl, pkg-config, openssl, cmocka }: stdenv.mkDerivation {
          name = "speculos";

          src = ./.; # fetchThunk ./nix/dep/speculos;

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

          #patches = [ ./speculos.patch ];
        }) {};
      })
    ];
  };
  inherit (speculosPkgs) speculosLauncher;
  speculos = pkgs.callPackage ({ stdenv, python36, qemu }: stdenv.mkDerivation {
    name = "speculos";
    src = ./.;
    buildPhase = "";
    buildInputs = [ (python36.withPackages (ps: with ps; [pyqt5 construct mnemonic pyelftools setuptools])) qemu ];
    installPhase = ''
    mkdir $out
    cp -a $src/speculos.py $out/
    cp -a $src/mcu $out/mcu
    install -d $out/build/src/
    ln -s ${speculosLauncher}/launcher $out/build/src/launcher
    '';
  }) {};
}
