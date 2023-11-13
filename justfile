build-packwiz-server:
    nix build .#packwiz-server

# build-packwiz-client:
#     nix build .#packwiz-client

build-mrpack:
    nix develop .#builder --command packwiz modrinth export

genereate-readme:
    cd generate-readme && poetry run generate-readme -- --manifest ../pack.toml --output ../README.md