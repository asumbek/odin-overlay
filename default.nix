self: super:

let
  pkgsSet = import ./pkgs.nix { pkgs = self; };
in
{
  odinToolchains = pkgsSet;
}
