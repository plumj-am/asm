{
  description = "FASM Nix Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    asm-lsp = {
      url = "github:bergercookie/asm-lsp/ba39d0155216fc7d6f011522a849126d3f9f461b";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      asm-lsp,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        asm-lsp-latest = pkgs.rustPlatform.buildRustPackage {
          pname = "asm-lsp";
          version = "unstable";
          src = asm-lsp;
          cargoHash = "sha256-4GbKT8+TMf2o563blj8lnZTD7Lc+z9yW11TfxYzDSg4=";
          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = with pkgs; [ openssl ];
          doCheck = false;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            fasm
            just
          ] ++ [ asm-lsp-latest ];
        };
      }
    );
}
