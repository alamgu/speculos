{ pkgs ? import ../nixpkgs {}, gitDescribe ? "TEST-dirty", nanoXSdk ? null, ... }:

rec {

  src = pkgs.lib.cleanSourceWith {
    filter = path: type: !(builtins.any (x: x == baseNameOf path) ["result" ".git" "tags" "TAGS" "dist"]);
    src = ./.;
  };

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
        speculosLauncher = speculosPkgs.callPackage ({ stdenv, cmake, ninja, perl, pkg-config, openssl, cmocka, libvncserver }: stdenv.mkDerivation {
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

          #patches = [ ./speculos.patch ];
        }) {};
      })
    ];
  };

  inherit (speculosPkgs) speculosLauncher;

  speculos-vnc = pkgs.callPackage ({stdenv, cmake, libvncserver} : stdenv.mkDerivation {
    name = "speculos-vnc";
    src = src + "/vnc";
    buildInputs = [ cmake libvncserver ];
    installPhase = ''
      mkdir $out
      cp -a vnc_server $out/
      echo "Install Phase"
    '';
  }) { };

  speculos = pkgs.callPackage ({ stdenv, python36, qemu, makeWrapper, libvncserver }: stdenv.mkDerivation {
    name = "speculos";
    inherit src;
    buildPhase = "";
    buildInputs = [ (python36.withPackages (ps: with ps; [pyqt5 construct mnemonic pyelftools setuptools])) qemu makeWrapper speculos-vnc ];
    installPhase = ''
    mkdir $out
    cp -a $src/speculos.py $out/
    install -d $out/bin
    ln -s $out/speculos.py $out/bin/speculos.py
      
    install -d $out/build/vnc
    ln -s ${speculos-vnc}/vnc_server $out/build/vnc/vnc_server

    cp -a $src/mcu $out/mcu
    install -d $out/build/src/
    ln -s ${speculosLauncher}/launcher $out/build/src/launcher
    makeWrapper $out/speculos.py $out/bin/speculos --set PATH $PATH
    '';
  }) {};

}
