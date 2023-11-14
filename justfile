build-packwiz-server:
    nix build .#packwiz-server

# build-packwiz-client:
#     nix build .#packwiz-client

build-mrpack:
    nix develop ./dev#builder --command packwiz modrinth export

genereate-readme:
    nix run ./dev#generate-readme -- --manifest pack.toml --output README.md

develop:
    nix develop ./dev#default