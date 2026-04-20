{ den, inputs, ... }:
{
  # flake-file.inputs = {
  #   nix-automatic-windows-vsts.url = "github:yaanae/nix-automatic-windows-vsts";
  #
  #   grace = {
  #     url =
  #       "file+https://osc.sfo2.digitaloceanspaces.com/Setup_Grace_64bit_Full_1-0-4-9_Windows.exe";
  #     flake = false;
  #   };
  # };
  #
  # den.aspects.vst-plugins = {
  #   includes = with den.aspects; [ custom-wine custom-yabridge ];
  #   nixos = { lib, pkgs, ... }: {
  #     imports = [
  #       inputs.nix-automatic-windows-vsts.nixosModules.nix-automatic-windows-vsts
  #     ];
  #
  #     environment.systemPackages = with pkgs; [
  #       yabridgectl
  #       yabridge
  #       wine-experimental
  #     ];
  #
  #     environment.variables = let
  #       makePluginPath = format:
  #         (lib.makeSearchPath format [
  #           "$HOME/.nix-profile/lib"
  #           "/run/current-system/sw/lib"
  #           "/etc/profiles/per-user/$USER/lib"
  #         ]) + ":$HOME/.${format}";
  #     in {
  #       DSSI_PATH = makePluginPath "dssi";
  #       LADSPA_PATH = makePluginPath "ladspa";
  #       LV2_PATH = makePluginPath "lv2";
  #       LXVST_PATH = makePluginPath "lxvst";
  #       VST_PATH = makePluginPath "vst";
  #       VST3_PATH = makePluginPath "vst3";
  #     };
  #
  #     nix-automatic-windows-vsts = {
  #       enable = true;
  #       plugins."grace" = {
  #         enable = true;
  #         install = ''
  #           cp ${inputs.grace} installer.exe
  #           wine installer.exe
  #         '';
  #       };
  #     };
  #   };
  #
  #   homeManager = { pkgs, lib, ... }: {
  #     home.activation.installVstPlugins =
  #       lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #         # Ensure the directory exists
  #         mkdir -p /home/vera/.vst/yabridge
  #
  #         # Symlink through the stable /run/current-system path rather than
  #         # directly into the store, so this survives yabridge version updates
  #         ln -sf /run/current-system/sw/bin/yabridge-host.exe \
  #           $HOME/.vst/yabridge/yabridge-host.exe
  #         ln -sf /run/current-system/sw/lib/yabridge/yabridge-host.exe.so \
  #           $HOME/.vst/yabridge/yabridge-host.exe.so
  #
  #         # windows-vst sync
  #       '';
  #   };
  # };

}
