{ ... }:
{
  den.aspects.native-vst-plugins = {
    # includes = with den.aspects; [ custom-wine custom-yabridge ];
    homeManager =
      {
        lib,
        config,
        pkgs,
        ...
      }:
      {
        home.packages = with pkgs; [

          # WARN: wine / yabridge / yabridgectl come from the windows-vst aspect.
          # Duplicating them here gives yabridge two wine versions to pick from.

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

          # vocal chain - VST3/CLAP, load directly in Bitwig
          airwin2rack # Airwindows Consolidated: DeBess de-esser, Pop, Pressure4, Console, ToTape
          dragonfly-reverb # plate/room/hall
          surge-xt # FX bank: Reverb2, Nimbus, chorus, delay
          distrho-ports # Luftikus EQ, TAL-Reverb-2/3, TAL-Vocoder (VST2/VST3)
          rnnoise-plugin # RNNoise room-noise strip
          zam-plugins # ZaMultiCompX2, ZamGateX2

          # vocal chain - LV2 only, host via carla.vst inside Bitwig
          x42-plugins # fil4 EQ, darc compressor, dpl limiter, zconvo, EBU meters
          calf # De-Esser, Vocoder
          aether-lv2 # lush algorithmic reverb
          ir-lv2 # impulse response loader

          carla
          jalv

        ];
        home.sessionVariables = {
          VST_PATH = "$HOME/.vst:$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst";
          VST3_PATH = "$HOME/.vst3:$HOME/.nix-profile/lib/vst3:/run/current-system/sw/lib/vst3";
          CLAP_PATH = "$HOME/.clap:$HOME/.nix-profile/lib/clap:/run/current-system/sw/lib/clap";
          LXVST_PATH = "$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
          LV2_PATH = "$HOME/.lv2:$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2";
          LADSPA_PATH = "$HOME/.ladspa:$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa";
          DSSI_PATH = "$HOME/.dssi:$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi";
        };

        # LV2 hosts do not recurse, so ~/.lv2 is symlinked whole - nesting bundles under ~/.lv2/nix/ makes every host report zero plugins.
        # VST2/VST3/CLAP scanners do recurse, so those get a "nix" subfolder to avoid colliding with the yabridge aspect on the parent directory.
        home.file = {
          ".lv2".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/lv2";
          ".lxvst".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/lxvst";

          ".vst/nix".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/vst";
          ".vst3/nix".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/vst3";
          ".clap/nix".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/clap";
        };
      };

  };

}
