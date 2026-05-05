{ den, ... }:
{
  den.aspects.windows-vst = {
    includes = [ den.aspects.yabridge ];
    nixos =
      { pkgs, lib, ... }:
      let
        # Directory containing plugin definitions
        pluginsDir = ./plugins;

        # Auto-discover all .nix files in the plugins directory (excluding files starting with _)
        pluginFiles = builtins.filter (name: lib.hasSuffix ".nix" name) (
          builtins.attrNames (builtins.readDir pluginsDir)
        );

        # Import each plugin as a package
        windowsPlugins = map (file: pkgs.callPackage (pluginsDir + "/${file}") { }) pluginFiles;

        # Create a bundle that symlinks all plugins together
        windowsPluginBundle = pkgs.runCommand "windows-plugin-bundle" { } ''
          mkdir -p $out
          ${lib.concatMapStringsSep "\n" (plugin: ''
            ln -s ${plugin}/* $out/ 2>/dev/null || true
          '') windowsPlugins}
        '';

      in
      {
        # Install required tools for Windows VST bridging
        environment.systemPackages =
          with pkgs;
          [
            # Wine for running Windows applications
            wine-staging
            winetricks

            # Yabridge for bridging Windows VSTs to Linux DAWs
            yabridge
            yabridgectl

            # The plugin bundle containing all discovered Windows VSTs
            windowsPluginBundle
          ]
          ++ windowsPlugins; # Also include individual plugins

        # Optional: Print discovered plugins during build
        # This helps verify that plugins are being discovered correctly
        system.activationScripts.windowsVstInfo = lib.stringAfter [ "etc" ] ''
          echo "Windows VST Plugins discovered: ${toString (builtins.length windowsPlugins)}"
          echo "Plugin files: ${lib.concatStringsSep ", " pluginFiles}"
        '';
      };
  };

}
