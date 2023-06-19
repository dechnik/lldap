{
  description = "Lldap";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs , rust-overlay}:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = nixpkgs.legacyPackages;
    in
    rec {
      nixosModules.default = import nix/module.nix self;

      packages = forAllSystems (system: {
        default = pkgsFor.${system}.callPackage nix/default.nix { inherit nixpkgs system rust-overlay; };
      });
      hydraJobs = packages;
    };
}
