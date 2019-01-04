{ mkDerivation, base, shake, stdenv }:
mkDerivation {
  pname = "install-nix";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base shake ];
  license = stdenv.lib.licenses.mpl20;
}
