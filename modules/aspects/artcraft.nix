{ inputs, ... }:
{
  # photocraft 0.16.0, built by Hydra. Separate pin so the main nixpkgs keeps its cache hits.
  flake-file.inputs.nixpkgs-photocraft.url = "github:NixOS/nixpkgs/31ecbaca1bdefa45dffc409f0250bd8039ea0010";

  den.aspects.artcraft = {
    homeManager =
      { pkgs, ... }:
      let
        # Not in nixpkgs; wrap the release AppImage.
        figcraft = pkgs.appimageTools.wrapType2 rec {
          pname = "figcraft";
          version = "0.12.1";
          src = pkgs.fetchurl {
            url = "https://github.com/storytold/figcraft/releases/download/v${version}/figcraft-${version}-linux-x86_64.AppImage";
            hash = "sha256-xSvgRte+pzeQ81hP/KbseTXfIprc6Pjkg7AyQu4qqx8=";
          };
          extraInstallCommands =
            let
              contents = pkgs.appimageTools.extract { inherit pname version src; };
            in
            ''
              install -Dm444 ${contents}/ai.storyteller.figcraft.desktop -t $out/share/applications
              cp -r ${contents}/usr/share/icons $out/share
            '';
        };
      in
      {
        home.packages = [
          inputs.nixpkgs-photocraft.legacyPackages.${pkgs.stdenv.hostPlatform.system}.photocraft
          figcraft
        ];
      };
  };
}
