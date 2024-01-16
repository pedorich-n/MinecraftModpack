{
  description = "FabricModpack Dev";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs = {
        systems.follows = "systems";
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        nix-github-actions.follows = "";
        treefmt-nix.follows = "";
      };
    };
  };

  outputs = inputs@{ flake-parts, systems, self, ... }: flake-parts.lib.mkFlake { inherit inputs; } ({
    systems = import systems;

    perSystem = { system, pkgs, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.poetry2nix.overlays.default ];
      };

      packages = {
        generate-readme = pkgs.callPackage ../generate-readme { };
      };

      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            packwiz
            poetry
          ];
        };
      };
    };
  });
}
