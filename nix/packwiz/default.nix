{ pkgs, ... }:
let
  sources = pkgs.callPackage ./_sources/generated.nix { };
in
pkgs.packwiz.overrideAttrs (_: _: {
  version = "unstable-${sources.packwiz.date}";
  inherit (sources.packwiz) src;
})
