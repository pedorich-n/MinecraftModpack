{ lib, stdenvNoCC, packwiz, jq, zip, unzip, moreutils }: { src, hash, ... } @ args:
stdenvNoCC.mkDerivation (finalAttrs:
let
  resultName = "${finalAttrs.passthru.manifest.name}-v${finalAttrs.passthru.manifest.version}.mrpack";
in
{
  pname = "${finalAttrs.passthru.manifest.name}_Modrinth";
  version = finalAttrs.passthru.manifest.version;

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = hash;

  dontFixup = true;

  buildInputs = [ packwiz jq unzip zip moreutils ];

  buildPhase = ''
    # this line needed for Github Action
    export HOME=$TMPDIR

    packwiz modrinth export --output ./${resultName}
  '';

  # modrinth.index.json file is not sorted, so non-deterministic :(
  # see https://github.com/packwiz/packwiz/issues/244
  installPhase = ''
    runHook preInstall 

    INDEX_FILE="modrinth.index.json"
    ZIP_FOLDER="$TMPDIR/unpack"
    JSON_FILE="$ZIP_FOLDER/$INDEX_FILE"

    unzip -q "./${resultName}" "$INDEX_FILE" -d "$ZIP_FOLDER"
    
    jq -S '.files|=sort_by(.path)' "$JSON_FILE" | sponge "$JSON_FILE"
    touch -acmt 197001010000.00 "$JSON_FILE"

    cd "$ZIP_FOLDER"
    zip -uXq "../${resultName}" modrinth.index.json

    mkdir -p $out
    mv ../${resultName} $out/

    runHook postInstall
  '';

  passthru = {
    manifest = lib.importTOML "${src}/pack.toml";
  };
} // args)
