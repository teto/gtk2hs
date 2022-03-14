{
  description = "Data frames for tabular data.";

  nixConfig = {
    extra-substituters = [
        "https://haskell-language-server.cachix.org"
    ];
    extra-trusted-public-keys = [
      "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    hls.url = "github:haskell/haskell-language-server";
  };

  outputs = { self, nixpkgs, hls, flake-utils}:

    flake-utils.lib.eachDefaultSystem (system: let

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      };

      compilerVersionFromHsPkgs = hsPkgs:
        pkgs.lib.replaceStrings [ "." ] [ "" ] hsPkgs.ghc.version;

      hspkgs810 = pkgs.haskell.packages."ghc8107".override {
        overrides = pkgs.frameHaskellOverlay-8107;
      };
      hspkgs92 = pkgs.haskell.packages."ghc921".override {
        overrides = pkgs.frameHaskellOverlay-921;
      };

      # mkPackage = hspkgs:
      #     hspkgs.developPackage {
      #       root =  pkgs.lib.cleanSource ./.;
      #       name = "Frames";
      #       returnShellEnv = false;
      #       withHoogle = true;
      #     };

      mkShell = hspkgs:
        let
          compilerVersion = compilerVersionFromHsPkgs hspkgs;
          myModifier = drv:
            pkgs.haskell.lib.addBuildTools drv (with hspkgs; [
              cabal-install
              hls.packages.${system}."haskell-language-server-${compilerVersion}"
              hasktags
            ]);
        in
        (myModifier (mkPackage hspkgs)).envFunc {};

      mkSimpleShell = compilerVersion:
        let
          compiler = pkgs.haskell.compiler."ghc${compilerVersion}";
        in
          pkgs.mkShell {
            buildInputs = [
              pkgs.haskell.compiler."ghc${compilerVersion}"
              pkgs.haskell.packages."ghc${compilerVersion}".cabal-install
              pkgs.llvmPackages_latest.llvm
              pkgs.glib
              pkgs.pango
              pkgs.cairo
              pkgs.gtk3
              pkgs.pkg-config
            ] ++
            pkgs.lib.optional (compilerVersion != "921")
              hls.packages.${system}."haskell-language-server-${compilerVersion}";
          };
  in {
    packages = {
      # Frames-921 = mkPackage hspkgs92;
    };

    devShell = mkSimpleShell "921";

    devShells = {
      # Frames-8107 = mkShell hspkgs810;
      Frames-921 = mkShell hspkgs92;
    };
  }) // {

    overlay = final: prev: {
    };
  };
}
