{
  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskellNix/nixpkgs-unstable";
    flakeUtils.url = "github:numtide/flake-utils";
    feedback.url = "github:NorfairKing/feedback";
  };

  outputs = { self, nixpkgs, haskellNix, flakeUtils, feedback }:
    let
      supportedSystems = [
        "x86_64-linux"
      ];
    in
      flakeUtils.lib.eachSystem supportedSystems (system:
        let
          overlays = [
            haskellNix.overlay
            (final: prev: {
              gibberishProject = final.haskell-nix.cabalProject' {
                src = ./.;
                compiler-nix-name = "ghc962";
                name = "gibberish";

                shell = {
                  tools = {
                    cabal = "latest";
                    haskell-language-server = "latest";
                  };

                  nativeBuildInputs = with final; [fourmolu hlint];
                  withHoogle = true;

                  # No cross platforms should speed up evaluation
                  crossPlatforms = _: [];
                };
              };
            })

            (final: prev: {
              fourmolu =
                final.haskell-nix.tool
                  final.gibberishProject.args.compiler-nix-name
                  "fourmolu"
                  "0.13.1.0";

              hlint =
                final.haskell-nix.tool
                  final.gibberishProject.args.compiler-nix-name
                  "hlint"
                  "latest";

              fourmoluCheck =
                prev.runCommand
                  "fourmolu-check"
                  { buildInputs = [final.fourmolu]; }
                  ''
                    cd "${final.gibberishProject.args.src}"
                    fourmolu --mode check src test
                    [[ "$?" -eq "0" ]] && touch $out
                  '';

              hlintCheck =
                prev.runCommand
                  "hlint-check"
                  { buildInputs = [final.hlint]; }
                  ''
                    cd "${final.gibberishProject.args.src}"
                    hlint src test
                    [[ "$?" -eq "0" ]] && touch $out
                  '';
            })
          ];

          pkgs = import nixpkgs {
            inherit system overlays;
            inherit (haskellNix) config;
          };

          flake = pkgs.gibberishProject.flake {
            crossPlatforms = p:
              pkgs.lib.optionals pkgs.stdenv.hostPlatform.isx86_64 (
                [p.mingwW64] ++
                (pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux
                  [p.musl64]));
          };
        in
          pkgs.lib.recursiveUpdate flake {
            checks = {
              inherit (pkgs) hlintCheck fourmoluCheck;
            };

            packages =
              let
                inherit (pkgs.stdenv.hostPlatform) isx86_64 isLinux;
              in {
                inherit (pkgs) hlintCheck fourmoluCheck;
                default = flake.packages."gibberish:exe:gibber";
              } // pkgs.lib.optionals isx86_64 {
                "cross/mingw64" = flake.packages."x86_64-w64-mingw32:gibberish:exe:gibber";
              } // pkgs.lib.optionals (isx86_64 && isLinux) {
                "cross/musl64" = flake.packages."x86_64-unknown-linux-musl:gibberish:exe:gibber";
              };
          });


  nixConfig = {
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "sgillespie.cachix.org-1:Zgif/WHW2IzHqbMb1z56cMmV5tLAA+zW9d5iB5w/VU4="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];

    substituters = [
      "https://cache.nixos.org/"
      "https://cache.iog.io"
      "https://sgillespie.cachix.org"
    ];

    allow-import-from-derivation = "true";
    experimental-features = ["nix-command flakes"];
  };
}
