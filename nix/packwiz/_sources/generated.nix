# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  packwiz = {
    pname = "packwiz";
    version = "7b4be47578151c36e784306b36d251ec2590e50c";
    src = fetchFromGitHub {
      owner = "packwiz";
      repo = "packwiz";
      rev = "7b4be47578151c36e784306b36d251ec2590e50c";
      fetchSubmodules = false;
      sha256 = "sha256-XBp8Xv55R8rhhsQiWnOPH8c3fCpV/yq41ozJDcGdWfs=";
    };
    date = "2024-05-27";
  };
}
