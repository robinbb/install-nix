{ mkDerivation, base, shake, stdenv }:
mkDerivation {
  pname = "shake-build-project";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base shake ];
  license = stdenv.lib.licenses.mpl20;
}
