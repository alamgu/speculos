import ./. { 
  pkgsFunc = import (import ./dep/ledger-platform/thunk.nix + "/dep/nixpkgs");
  inherit (import ./dep/ledger-platform {}) pkgs;
}
