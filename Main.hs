-- Install the Nix package manager by downloading a binary distribution and
-- running its installer script (which in turn creates and populates /nix).

import Data.Char (toLower, isSpace)
import Data.List (dropWhileEnd)
import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util

-- Constants
nixVersion = "2.1.3"
tarballsDir = "_build/tarballs"

-- Utility functions
bin exe = "_build" </> "bin" </> exe
rtrim   = dropWhileEnd isSpace
mkdir d = cmd_ "mkdir -p" d

main = shakeArgs shakeOptions{shakeFiles="_build"} $ do

    -- Nix is installed if its SQLite database file is in place.
    -- This is the overall build target for this program.
    want ["/nix/var/nix/db/db.sqlite"]

    -- Rule for building anything under `/nix`:
    "/nix//*" %> \_ -> do
      system <- readFile' "_build/system"
      let distro = "nix-" ++ nixVersion ++ "-" ++ system
      let tarball = tarballsDir </> distro <.> "tar" <.> "bz2"
      let unpackDir = "_build/unpack"
      let tar = bin "tar"
      let bzcat = bin "bzcat"
      need [tar, bzcat, tarball]
      mkdir unpackDir
      cmd_ Shell "<" tarball bzcat
                 "|" tar "-xf -" "-C" unpackDir
      let installer = unpackDir </> distro </> "install"
      need [installer]  -- Ensure the installer is where it should be.
      cmd_ installer    -- Invoke the installation script packaged with Nix.

    -- Rule for obtaining the tarball:
    (tarballsDir </> "*") %> \target -> do
      let nixVer = "nix-" ++ nixVersion
      let tarball = takeFileName target
      let url = "https://nixos.org/releases/nix/" ++ nixVer ++ "/" ++ tarball
      let curl = bin "curl"
      need [curl]
      mkdir tarballsDir
      cmd_ curl "-L" url "-o" target

    -- Rule for ensuring we have the necessary binary utilities:
    bin "*" %> \utility -> do
       let baseName = takeBaseName utility
       Stdout fullPath <- cmd "which" baseName
       cmd_ "ln -sf" [rtrim fullPath, utility]

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
