let
  pkgs = import <nixpkgs> { };
in
  { install-nix =
      pkgs.haskellPackages.callPackage ./install-nix.nix { };
  }
