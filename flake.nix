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
    {
      # nixosModules.default = import nix/module.nix;

      # packages = forAllSystems (system: let
      #   code = pkgsFor.${system}.callPackage nix/default.nix { inherit nixpkgs system rust-overlay; };
      # in rec {
      #   backend = code.backend;
      #   frontend = code.frontend;
      #   all = pkgsFor.${system}.symlinkJoin {
      #     name = "all";
      #     paths = with code; [ backend frontend ];
      #   };
      #   default = all;
      # });
      packages = forAllSystems (system: {
        default = pkgsFor.${system}.callPackage nix/default.nix { inherit nixpkgs system rust-overlay; };
      });

      # devShells = forAllSystems (system: {
      #   default = pkgsFor.${system}.callPackage nix/shell.nix { };
      # });
    };
}
