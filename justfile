build-packwiz-server:
    nix build .#packwiz-server

# build-packwiz-client:
#     nix build .#packwiz-client

genereate-readme:
    cd generate-readme && poetry run generate-readme -- --root ../ && mv README.md ../