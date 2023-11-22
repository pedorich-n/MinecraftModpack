set dotenv-load

build-packwiz-server:
    nix build .#packwiz-server --print-out-paths

# build-packwiz-client:
#     nix build .#packwiz-client

build-mrpack:
    nix build .#modrinth-pack --print-out-paths

genereate-readme:
    nix run ./dev#generate-readme -- --manifest pack.toml --output README.md ${CF_API_KEY:+--cf-key "$CF_API_KEY"}

develop:
    nix develop ./dev#default