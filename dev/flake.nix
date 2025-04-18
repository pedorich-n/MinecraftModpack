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

    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    systems,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;

      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
      ];

      perSystem = {
        config,
        system,
        pkgs,
        inputs',
        lib,
        ...
      }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.poetry2nix.overlays.default];
        };

        packages = {
          generate-readme = pkgs.callPackage ../generate-readme {};
          update-hash = pkgs.callPackage ../update-hash {};
        };

        pre-commit = {
          settings = {
            src = ./..;
            hooks = {
              update-hash = let
                inherit (self.packages.${system}) update-hash;
              in {
                enable = true;
                entry = "${lib.getExe update-hash} run";
                fail_fast = true;
                files = "(\\.toml$|\\.nix$|^flake.lock$)";
                pass_filenames = false;
                package = update-hash;
                stages = ["pre-push"];
              };

              check-flake = {
                enable = true;
                entry = "nix flake check";
                always_run = true;
                pass_filenames = false;
                after = ["update-hash"];
                stages = ["pre-push"];
              };
            };
          };
        };

        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nvfetcher
              packwiz
              poetry
            ];
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };
        };
      };
    };
}
