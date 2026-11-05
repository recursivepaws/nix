{ den, ... }:
{
  den.aspects.artcraft =
    {
      user ? null,
      ...
    }:
    {
      homeManager =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          home = config.home.homeDirectory;
          # Release AppImages, not nixpkgs: upstream ships several minor versions ahead of what Hydra builds.
          # Both AppImages share one layout: desktop file and icon at the root, icons under usr/share.
          craftApp =
            pname: version: hash:
            pkgs.appimageTools.wrapType2 rec {
              inherit pname version;
              src = pkgs.fetchurl {
                url = "https://github.com/storytold/${pname}/releases/download/v${version}/${pname}-${version}-linux-x86_64.AppImage";
                inherit hash;
              };
              extraInstallCommands =
                let
                  contents = pkgs.appimageTools.extract { inherit pname version src; };
                in
                ''
                  install -Dm444 ${contents}/ai.storyteller.${pname}.desktop -t $out/share/applications
                  cp -r ${contents}/usr/share/icons $out/share
                '';
            };
          photocraft = craftApp "photocraft" "0.20.2" "sha256-vhjRdaCmJ4wwEkJBeTu3ezV++WBG2B8dgYnkksFLwK4=";
          figcraft = craftApp "figcraft" "0.15.1" "sha256-9wvCPup0rNp1kC4VxkJqQ21mRKCDQOU9S2N4dCefW4c=";
          # Headless MCP denies all file access unless each direction gets a root.
          automationRoots = [
            "--automation-read-root"
            home
            "--automation-write-root"
            "${home}/Pictures"
          ];
        in
        {
          home.packages = [
            photocraft
            figcraft
          ];
        }
        # optionalAttrs, not mkIf: mcp-servers options only exist when claude imports mcp-servers-nix.
        // lib.optionalAttrs (user != null && user.hasAspect den.aspects.claude) {
          # Each AppRun runs the bundled headless CLI instead of the app on its CLI flag.
          mcp-servers.settings.servers = {
            photocraft = {
              command = "${photocraft}/bin/photocraft";
              args = [
                "--cli"
                "mcp"
              ]
              ++ automationRoots;
            };
            figcraft = {
              command = "${figcraft}/bin/figcraft";
              args = [
                "cli"
                "mcp"
              ]
              ++ automationRoots;
            };
          };
        };
    };
}
