{ ... }: {
  den.aspects.native-vst-plugins = {
    # includes = with den.aspects; [ custom-wine custom-yabridge ];
    homeManager = { lib, config, pkgs, ... }: {
      home.packages = with pkgs; [

        yabridge
        wineWowPackages.staging
        winetricks
        yabridge
        yabridgectl

        # airwave
        # surge
        # surge-XT
        vital
        cardinal

        zlsplitter
        zlcompressor
        zlequalizer
        uhhyou-plugins
        chow-tape-model
        lsp-plugins
        linvstmanager

        carla
        jalv

      ];
      home.sessionVariables = {
        VST_PATH =
          "$HOME/.vst:$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst";
        VST3_PATH =
          "$HOME/.vst3:$HOME/.nix-profile/lib/vst3:/run/current-system/sw/lib/vst3";
        LXVST_PATH =
          "$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
        LV2_PATH =
          "$HOME/.lv2:$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2";
        LADSPA_PATH =
          "$HOME/.ladspa:$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa";
        DSSI_PATH =
          "$HOME/.dssi:$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi";
      };

      # ===================================================================
      # CREATE PLUGIN DIRECTORY SYMLINKS
      # This makes plugins accessible in standard locations
      # ===================================================================
      home.file = {
        # LV2 plugins symlink
        ".lv2".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.profileDirectory}/lib/lv2";

        # VST plugins symlink
        ".vst".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.profileDirectory}/lib/vst";

        # VST3 plugins symlink
        ".vst3".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.profileDirectory}/lib/vst3";

        # LXVST plugins symlink
        ".lxvst".source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.profileDirectory}/lib/lxvst";
      };
    };

  };

}
