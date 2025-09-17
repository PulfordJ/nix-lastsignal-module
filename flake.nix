{
  description = "LastSignal NixOS module - automated safety check-in system";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    lastsignal-src = {
      url = "github:PulfordJ/lastsignal";
      flake = false;
    };
  };
  
  outputs = { self, nixpkgs, flake-utils, lastsignal-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.callPackage ./default.nix { inherit lastsignal-src; };
      }
    ) // {
      nixosModules.default = { config, lib, pkgs, ... }:
        import ./default.nix { inherit config lib pkgs lastsignal-src; };
      nixosModules.lastsignal = { config, lib, pkgs, ... }:
        import ./default.nix { inherit config lib pkgs lastsignal-src; };
    };
}