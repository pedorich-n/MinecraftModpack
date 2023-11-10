{ lib, stdenvNoCC, packwiz }: { src, ... } @ args:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = finalAttrs.passthru.manifest.name;
  version = finalAttrs.passthru.manifest.version;

  dontFixup = true;

  buildInputs = [ packwiz ];

  buildPhase =
    let
      resultName = "${finalAttrs.pname}-${finalAttrs.version}.mrpack";
    in
    ''
      mkdir -p $out

      ${lib.getExe packwiz} modrinth export --output ./${resultName}

      mv ./${resultName} $out/
    '';

  passthru = {
    manifest = lib.trace src lib.importTOML "${src}/pack.toml";
  };
} // args)
