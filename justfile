build-modrinth:
    nix build .#pack-modrinth --print-out-paths

build-packwiz-server:
    nix build .#packwiz-server

build-packwiz-client:
    nix build .#packwiz-client