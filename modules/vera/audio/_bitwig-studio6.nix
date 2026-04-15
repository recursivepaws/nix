{ inputs, ... }: {
  flake-file.inputs.audio-nix.url = "github:polygon/audio.nix";

  flake.modules.nixos.bitwig-studio6 = { pkgs, ... }: {
    # Use Bitwig Studio package from audio.nix
    environment.systemPackages = [
      (pkgs.callPackage "${inputs.audio-nix}/bitwig/bitwig-studio-6.0-beta.nix"
        { })
    ];

    # Allow unfree license for Bitwig
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (pkgs.lib.getName pkg) [ "bitwig-studio" ];
  };
}
