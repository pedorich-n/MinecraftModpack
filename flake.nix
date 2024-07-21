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

          # For Modpack Devolopers:
          # These builds expects *Double Invocation*
          # Without a proper hash, the first build _will_ fail. 
          # The failed result will tell you the expected `hash` to assign below.
          # When you've set the hash, the next build will return with a `/nix/store` entry of the results, 
          # symlinked as `./result`.

          modrinth-pack-hash = "sha256-SOU2A4xshrw2i+WVa/Fvsfm2Y2Fv4pl6BiFaskHFmCE=";
            manifest = "${self}/pack.toml";
            hash = packwiz-pack-hash;
            side = "server";
          };

          modrinth-pack = pkgs.callPackage ./nix/packwiz-modrinth.nix {
            src = self;
            hash = modrinth-pack-hash;
          };
          
        };

      checks = config.packages;
    };
  });
}
