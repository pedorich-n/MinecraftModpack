set dotenv-load

build-packwiz-server *args:
    nix build .#packwiz-server --print-out-paths {{args}}

# build-packwiz-client:
#     nix build .#packwiz-client

build-mrpack *args:
    nix build .#modrinth-pack --print-out-paths {{args}}

genereate-readme:
    nix run ./dev#generate-readme -- --manifest pack.toml --output README.md ${CF_API_KEY:+--cf-key "$CF_API_KEY"}

develop:
    nix develop ./dev#default