{
  description = "A GUI library for writing native Haskell applications.";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/master";
    nixpkgs.url = "github:nixos/nixpkgs/haskell-updates";
  };
  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    eachSystem [ "x86_64-darwin" ] (system:
      let
        isLinux = (import nixpkgs { inherit system; }).stdenv.isLinux;
        version = with nixpkgs.lib;
          "${substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
        overlays = [
          (import ./nix/monomer.nix { inherit system version flake-utils; })
          (if isLinux then
            (import ./nix/qemu.nix {
              inherit system version flake-utils nixpkgs;
            })
          else
            (self: super: { }))
        ];
      in with (import nixpkgs { inherit system overlays; }); rec {
        packages = flattenTree (recurseIntoAttrs (if isLinux then {
          inherit (libraries) monomer;
          inherit (qemu) nixos;
        } else {
          inherit (libraries) monomer;
        }));
        apps = executables // (if isLinux then {
          nixos = mkApp {
            drv = qemu.nixos;
            name = "run-nixos-vm";
          };
        } else
          { });
        defaultPackage = packages.monomer;
        defaultApp = apps.tutorial;
      });
}
