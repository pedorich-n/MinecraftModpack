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

    modpack = {
      url = "gitlab:pablo_peraza/modpack-londoism";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, systems, packwiz2nix, self, modpack, ... }: flake-parts.lib.mkFlake { inherit inputs; } ({ moduleWithSystem, ... }: {
    systems = import systems;

    perSystem = { system, pkgs, config, lib, ... }: {
      packages =
        let
          packwiz2nixLib = inputs.packwiz2nix.lib.${system};
        in
        {
          packwiz-server = packwiz2nixLib.fetchPackwizModpack {
            manifest = "${modpack}/pack.toml";
            hash = "sha256-0b7JQa3L/rGKjl+Mn0w11zWz34McpUn2bz+1WsDfWYQ=";
            side = "server";
          };

          # Not used for anything right now
          # modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
          #   src = self;
          #   hash = "sha256-qPfIgqP6Xv4tt2p8xnDsspW540Q2We6nWUGYiJynyvM=";
          # };

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
