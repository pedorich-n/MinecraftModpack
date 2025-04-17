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
  };

  outputs = inputs @ {
    flake-parts,
    systems,
    packwiz2nix,
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
        packages = let
          packwiz2nixLib = inputs.packwiz2nix.lib.${system};
          # These packs expects to be built using *Double Invocation*
          # Without proper hash, the first build of any pack _will_ fail.
          # Run `nix flake check ./?dir=dev&submodules=1` will give you the correct hash to assign below.
          # When you've set the hash, the next build will return with a `/nix/store` location
          # of the entry of the modpack, which will also be symlinked into `./result/`.
          packwiz-server-hash = "sha256-JDdkCLeIdnHpTbEUA8WkH6G/0flbXBkHrYF9N/AlG8k=";
          modrinth-pack-hash = "sha256-uBBfGeC+cOhaLHLUkx56K7qNhFplUTmeboZsbPbG3Eo=";
        in {
          packwiz-server = packwiz2nixLib.fetchPackwizModpack {
            manifest = "${self}/pack.toml";
            hash = packwiz-server-hash;
            side = "server";
          };

          modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
            src = self;
            hash = modrinth-pack-hash;
          };

          # Not used for anything right now
          # packwiz-client = packwiz2nixLib.fetchPackwizModpack {
          #   manifest = "${self}/pack.toml";
          #   hash = "sha256-cd3NdmkO3yaLljNzO6/MR4Aj7+v1ZBVcxtL2RoJB5W8=";
          #   side = "client";
          # };
        };

        checks = config.packages;
      };
    });
}
