{pkgs}:
pkgs.writeShellApplication rec {
  name = "update-hash";
  text = builtins.readFile ./${name}.bash;
}
