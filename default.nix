let
  pkgs = import <nixpkgs> { };
in
  { shake-build-project =
      pkgs.haskellPackages.callPackage ./install-nix.nix { };
  }
