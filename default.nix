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
        openssl2 = super.openssl.overrideAttrs (orig: {
          src = super.fetchFromGitHub {
            owner = "openssl";
            repo = "openssl";
            # branch = "JemmyLoveJenny:ecdsa_deterministic_signature";
            rev = "bf73df3ba616409f30f7fe345ab6257aa1cd2ca8";
            sha256 = "0hr1fawxwymzbg00by1kqdgwy6r2g7crdg8xkxd2s1nmkpdr3zz6";
          };
        });
        speculosLauncher = speculosPkgs.callPackage ({ stdenv, cmake, ninja, perl, pkg-config, openssl2, cmocka }: stdenv.mkDerivation {
          name = "speculos";

          src = ./.; # fetchThunk ./nix/dep/speculos;

          nativeBuildInputs = [ 
            cmake
            ninja
            perl
            pkg-config
          ];

          buildInputs = [
            openssl2
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
  speculos = pkgs.callPackage ({ stdenv, python36, qemu, makeWrapper }: stdenv.mkDerivation {
    name = "speculos";
    src = ./.;
    buildPhase = "";
    buildInputs = [ (python36.withPackages (ps: with ps; [pyqt5 construct mnemonic pyelftools setuptools])) qemu makeWrapper ];
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
