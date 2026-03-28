{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs@{ flake-parts, nixpkgs, naersk, rust-overlay, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      
      perSystem = { config, self', inputs', pkgs, system, ... }: 
        let
          # 1. Overlay anwenden für die Rust-Toolchain
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import rust-overlay) ];
          };

          # 2. Spezifische Nightly Toolchain definieren
          # Hinweis: 1.48.0 ist sehr alt, für nutype/rustdoc-json empfehle ich eine neuere.
          # Ich nutze hier deine gewünschte Syntax.
          rustToolchain = pkgs.rust-bin.nightly."2025-12-15".default.override {
            extensions = [ "rust-src" "rust-docs" ];
          };

          # 3. Naersk mit dieser Toolchain konfigurieren
          naersk-lib = pkgs.callPackage naersk {
            rustc = rustToolchain;
            cargo = rustToolchain;
          };
        in {
          # Das Haupt-ERP Paket
          packages.default = naersk-lib.buildPackage {
            src = ./.;
            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = with pkgs; [ openssl sqlite postgresql ];
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [ rustToolchain pkgs.pkg-config pkgs.sqlite pkgs.postgresql ];
          };
        };
    };
}
