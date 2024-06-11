{ src
, hash
, lib
, stdenvNoCC
, packwiz
, strip-nondeterminism
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

  nativeBuildInputs = [ packwiz strip-nondeterminism ];

  buildPhase = ''
    runHook preBuild

    # Github Ation fails with "failed to create cache directory: mkdir /homeless-shelter: permission denied" if this is not set
    export HOME=$TMPDIR

    result="$out/${resultName}"

    mkdir -p $out
    packwiz modrinth export --output "$result"

    strip-nondeterminism --type zip "$result"

    runHook postBuild
  '';

  passthru = {
    manifest = lib.importTOML "${src}/pack.toml";
  };
})
