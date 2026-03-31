{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flakelight.url = "github:nix-community/flakelight";
    flakelight-treefmt.url = "github:m15a/flakelight-treefmt";

    flakelight.inputs.nixpkgs.follows = "nixpkgs";
    flakelight-treefmt.inputs.flakelight.follows = "flakelight";
  };
  outputs =
    { flakelight, ... }@inputs:
    flakelight ./. {
      inherit inputs;

      imports = with inputs; [
        flakelight-treefmt.flakelightModules.default
      ];

      overlay = import ./default.nix;

      perSystem = pkgs: {
        packages =
          let
            pkgsSet = import ./pkgs.nix { inherit pkgs; };
          in
          pkgsSet;
      };

      treefmtConfig =
        { ... }:
        {
          programs.nixfmt.enable = true;
        };
    };
}
