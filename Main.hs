-- Install the Nix package manager by downloading a binary distribution and
-- running its installer script (which in turn creates and populates /nix).

import Data.Char (toLower, isSpace)
import Data.List (dropWhileEnd)
import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util

nixVersion = "2.1.3"
tarballsDir = "_build/tarballs"
rtrim = dropWhileEnd isSpace

main = shakeArgs shakeOptions{shakeFiles="_build"} $ do

    -- Nix is installed if its SQLite database file is in place.
    -- This is the overall build target for this program.
    want ["/tmp/nix/var/nix/db/db.sqlite"]

    -- Rule for building anything under `/nix`:
    "/tmp/nix//*" %> \_ -> do
      let installer = "_build/install"
      need [installer]
      cmd_ installer  -- Invoke the installation script packaged with Nix.

    -- Rule for obtaining the Nix installation script:
    "_build/install" %> \installer -> do
      system <- readFile' "_build/system"
      let tarball = tarballsDir ++ "/nix-" ++ system ++ ".tar.bz2"
      let unpackDir = "_build/unpack"
      let tar = "_build/bin/tar"
      let bzcat = "_build/bin/bzcat"
      need [tar, bzcat, tarball]
      cmd_ $ "mkdir -p " ++ unpackDir
      cmd_ Shell $ "< " ++ tarball ++ " " ++ bzcat ++ " | "
                   ++ tar ++ " -xf - -C " ++ unpackDir
      cmd_ $ "ln -sf " ++ unpackDir ++ "/*/install " ++ installer

    -- Rule for obtaining the tarball:
    (tarballsDir </> "*") %> \target -> do
      let nixVer = "nix-" ++ nixVersion
      let tarball = takeBaseName target
      let url = "https://nixos.org/releases/nix/" ++ nixVer ++ "/" ++ tarball
      let curl = "_build/bin/curl"
      need [curl]
      cmd_ $ "mkdir -p " ++ tarballsDir
      cmd_ $ curl ++ " -L " ++ url ++ " -o " ++ target

    -- Rule for ensuring we have the necessary binary utilities:
    "_build/bin/*" %> \utility -> do
       let baseName = takeBaseName utility
       Stdout fullPath <- cmd $ "which " ++ baseName
       cmd_ $ "ln -sf " ++ fullPath ++ " " ++ utility

    -- Rules for determining the operating system and architecture:
    "_build/system" %> \it -> do
      need ["_build/os", "_build/arch"]
      os <- readFile' "_build/os"
      arch <- readFile' "_build/arch"
      writeFileChanged it (arch ++ "-" ++ map toLower os)
    "_build/arch" %> \it -> do
      Stdout arch <- cmd "uname -m"
      writeFileChanged it (rtrim arch)
    "_build/os" %> \it -> do
      Stdout os <- cmd "uname -s"
      writeFileChanged it (rtrim os)

    -- Emulate `make clean`:
    phony "clean" $ removeFilesAfter "_build" ["//*"]

--    "_build/run" <.> exe %> \out -> do
--      cs <- getDirectoryFiles "" ["//*.c"]
--      let os = ["_build" </> c -<.> "o" | c <- cs]
--      need os
--      cmd_ "gcc -o" [out] os
--
--    "_build//*.o" %> \out -> do
--      let c = dropDirectory1 $ out -<.> "c"
--      let m = out -<.> "m"
--      cmd_ "gcc -c" [c] "-o" [out] "-MMD -MF" [m]
--      needMakefileDependencies m
