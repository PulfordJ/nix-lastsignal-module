{
  description = "LastSignal NixOS module - automated safety check-in system";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.callPackage ./default.nix {};
      }
    ) // {
      nixosModules.default = import ./default.nix;
      nixosModules.lastsignal = import ./default.nix;
    };
}