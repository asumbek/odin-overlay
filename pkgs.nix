{
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (builtins)
    readFile
    mapAttrs
    attrValues
    listToAttrs
    ;

  makePackagesMapper =
    templateFile:
    (
      releaseName: srcs:
      let
        template = import templateFile { inherit releaseName srcs; };
      in
      {
        name = releaseName;
        value = pkgs.callPackage template { };
      }
    );

  getManifest = name: fromTOML (readFile ./manifests/${name}.toml);

  makePackages =
    name:
    let
      manifest = getManifest name;
      packagesAttrs = mapAttrs (makePackagesMapper ./package-templates/${name}.nix) manifest;
      packages = listToAttrs (attrValues packagesAttrs);
    in
    packages;
in
{
  odin = makePackages "odin";
  ols = makePackages "ols";
}
