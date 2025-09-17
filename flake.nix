{
  description = "LastSignal NixOS module - automated safety check-in system";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane.url = "github:ipetkov/crane";
    lastsignal-src = {
      url = "github:PulfordJ/lastsignal";
      flake = false;
    };
  };
  
  outputs = { self, nixpkgs, flake-utils, crane, lastsignal-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.mkLib pkgs;
      in {
        packages.default = craneLib.buildPackage {
          src = lastsignal-src;
          buildInputs = with pkgs; [
            openssl
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.Security
            pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
          ];
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
        };
      }
    ) // {
      nixosModules.default = { config, lib, pkgs, ... }:
        let craneLib = crane.mkLib pkgs; in
        import ./default.nix { inherit config lib pkgs lastsignal-src; crane = craneLib; };
      nixosModules.lastsignal = { config, lib, pkgs, ... }:
        let craneLib = crane.mkLib pkgs; in
        import ./default.nix { inherit config lib pkgs lastsignal-src; crane = craneLib; };
    };
}