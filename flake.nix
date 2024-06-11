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

  outputs = inputs@{ flake-parts, systems, packwiz2nix, self, ... }: flake-parts.lib.mkFlake { inherit inputs; } ({ moduleWithSystem, ... }: {
    systems = import systems;

    perSystem = { system, pkgs, config, lib, ... }: {
      _module.args = {
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (import ./nix/overlay.nix)
          ];
        };
      };

      packages =
        let
          packwiz2nixLib = inputs.packwiz2nix.lib.${system};
        in
        {
          packwiz-server = packwiz2nixLib.fetchPackwizModpack {
            manifest = "${self}/pack.toml";
            hash = "sha256-PgW+pnpd548agb4UdXgtxp5tMqJ/1pUT8Pk2DkD2U0M=";
            side = "server";
          };

          modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
            src = self;
            hash = "sha256-ie0Igriqj77fmhcRyJtUxqJKAI+db1+dNF3QgyVi7P4=";
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
