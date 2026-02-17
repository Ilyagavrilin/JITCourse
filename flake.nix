{
  description = "Simple typst setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            typst
            typstyle
            tinymist
            just

            jetbrains-mono
            google-fonts
            fontconfig
          ];

          FONTCONFIG_FILE = pkgs.makeFontsConf {
            fontDirectories = [
              pkgs.jetbrains-mono
              pkgs.google-fonts
            ];
          };

        };
      });
}
