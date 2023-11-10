build-modrinth:
    packwiz modrinth export

build-packwiz-server:
    nix build .#packwiz-server

build-packwiz-client:
    nix build .#packwiz-client