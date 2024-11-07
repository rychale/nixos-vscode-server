{
  description = "NixOS VSCode server";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    alejandra,
    nixpkgs,
    flake-utils,
  }:
    {
      nixosModule = self.nixosModules.default; # Deprecrated, but perhaps still in use.
      nixosModules.default = import ./modules/vscode-server;
      nixosModules.home = self.homeModules.default; # Backwards compatiblity.
      homeModules.default = import ./modules/vscode-server/home.nix; # Consistent with homeConfigurations.

      formatter = {
        x86_64-linux = alejandra.packages.x86_64-linux.default;
      };
    }
    // (
      let
        inherit (flake-utils.lib) defaultSystems eachSystem;
      in
        eachSystem defaultSystems (system: let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs.lib) hasSuffix optionalAttrs;
          auto-fix-vscode-server = pkgs.callPackage ./pkgs/auto-fix-vscode-server.nix {};
        in
          # The package depends on `inotify-tools` which is only available on Linux.
          optionalAttrs (hasSuffix "-linux" system) {
            packages = {
              inherit auto-fix-vscode-server;
              default = auto-fix-vscode-server;
            };
            checks = {
              inherit auto-fix-vscode-server;
            };
            system = "x86_64-linux";
          })
    );
}
