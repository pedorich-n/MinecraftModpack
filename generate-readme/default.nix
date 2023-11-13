{ pkgs }:
pkgs.poetry2nix.mkPoetryApplication {
  projectDir = ./.;
  checkGroups = [ ]; # To omit dev dependencies
  overrides = pkgs.poetry2nix.overrides.withDefaults (_: prev: {
    modrinth = prev.modrinth.overridePythonAttrs (old: { buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ]; });
  });
}