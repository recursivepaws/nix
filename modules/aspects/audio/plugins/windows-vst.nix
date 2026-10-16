{ den, ... }:
{
  den.aspects.windows-vst = {
    includes = [ den.aspects.yabridge ];
    nixos =
      { pkgs, lib, ... }:
      let
        pluginsDir = ./plugins;

        pluginFiles = builtins.filter (name: lib.hasSuffix ".nix" name) (
          builtins.attrNames (builtins.readDir pluginsDir)
        );

        windowsPlugins = map (file: pkgs.callPackage (pluginsDir + "/${file}") { }) pluginFiles;

        # HACK: collisions between plugins are swallowed; first one linked wins.
        windowsPluginBundle = pkgs.runCommand "windows-plugin-bundle" { } ''
          mkdir -p $out
          ${lib.concatMapStringsSep "\n" (plugin: ''
            ln -s ${plugin}/* $out/ 2>/dev/null || true
          '') windowsPlugins}
        '';

      in
      {
        environment.systemPackages =
          with pkgs;
          [
            wine-staging
            winetricks
            yabridge
            yabridgectl
            windowsPluginBundle
          ]
          ++ windowsPlugins;

        system.activationScripts.windowsVstInfo = lib.stringAfter [ "etc" ] ''
          echo "Windows VST Plugins discovered: ${toString (builtins.length windowsPlugins)}"
          echo "Plugin files: ${lib.concatStringsSep ", " pluginFiles}"
        '';
      };
  };

}
