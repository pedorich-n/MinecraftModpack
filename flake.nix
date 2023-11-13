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

    perSystem = { system, pkgs, ... }: {
      packages =
        let
          packwiz2nixLib = inputs.packwiz2nix.lib.${system};
        in
        {
          packwiz-server = packwiz2nixLib.fetchPackwizModpack {
            manifest = "${self}/pack.toml";
            hash = "sha256-9TSisKji+yr6uEmoGNCRcIcxGz/c4ZRqko0J9G6ukyA=";
            side = "server";
          };

          # Not used for anything right now
          # packwiz-client = packwiz2nixLib.fetchPackwizModpack {
          #   manifest = "${self}/pack.toml";
          #   hash = "sha256-cd3NdmkO3yaLljNzO6/MR4Aj7+v1ZBVcxtL2RoJB5W8=";
          #   side = "client";
          # };
        };
    };
  });
}
