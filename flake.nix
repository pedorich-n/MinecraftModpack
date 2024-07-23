{
  description = "FabricModpack";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    packwiz2nix = {
      url = "github:getchoo/packwiz2nix/rewrite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    packwiz2nixMain.url = "github:Joaqim/packwiz2nix/?ref=fix/sanitize-store-paths";
  };

  outputs = inputs @ {
    flake-parts,
    systems,
    packwiz2nix,
    packwiz2nixMain,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({moduleWithSystem, ...}: {
      systems = import systems;

      perSystem = {
        system,
        pkgs,
        config,
        lib,
        ...
      }: {
        _module.args = {
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (import ./nix/overlay.nix)
            ];
          };
        };

        apps = {
          generate-checksums = packwiz2nixMain.lib.mkChecksumsApp pkgs ./mods;
        };

        packages = let
          inherit (packwiz2nix.lib.${system}) fetchPackwizModpack;
          inherit (packwiz2nixMain.lib) mkMultiMCPack mkPackwizPackages mkChecksums;

          # For Modpack Devolopers:
          # These builds expects *Double Invocation*
          # Without a proper hash, the first build _will_ fail.
          # The failed result will tell you the expected `hash` to assign below.
          # When you've set the hash, the next build will return with a `/nix/store` entry of the results,
          # symlinked as `./result`.

          packwiz-pack-hash = "sha256-z3qFcUPGxSXV3OymwPqn+lgjmYGG+G5X2sirm4dXGLc=";
          modrinth-pack-hash = "sha256-MrxGRiA7vruKjxbdDEnA2HO+1QJnb6h+ynazyGDpCwc=";
        in {
          packwiz-server = fetchPackwizModpack {
            manifest = "${self}/pack.toml";
            hash = packwiz-pack-hash;
            side = "server";
          };

          modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
            src = self;
            hash = modrinth-pack-hash;
          };
          /*
          multimc-pack = let
            checksums = mkChecksums pkgs ./mods;
            mods = mkPackwizPackages pkgs checksums;
          in
            mkMultiMCPack {
              inherit pkgs mods;
              name = "Joaqim-s-Minecraft-Modpack";
            };
          */
        };

        checks = config.packages;
      };
    });
}
