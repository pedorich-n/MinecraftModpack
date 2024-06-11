{ src
, hash
, lib
, stdenvNoCC
, packwiz
}:
stdenvNoCC.mkDerivation (finalAttrs:
let
  sanitizedName = lib.strings.sanitizeDerivationName finalAttrs.passthru.manifest.name;
  version = finalAttrs.passthru.manifest.version;
  resultName = "${sanitizedName}-v${version}.mrpack";
in
{
  pname = "${sanitizedName}_Modrinth";
  inherit version;
  inherit src;

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = hash;

  dontFixup = true;

  buildInputs = [ packwiz ];

  buildPhase = ''
    runHook preBuild

    # Github Ation fails with "failed to create cache directory: mkdir /homeless-shelter: permission denied" if this is not set
    export HOME=$TMPDIR

    mkdir -p $out
    packwiz modrinth export --output "$out/${resultName}"

    runHook postBuild
  '';

  passthru = {
    manifest = lib.importTOML "${src}/pack.toml";
  };
})
