{
  flake.modules.nixos.lsp-plugins-vst = { pkgs, ... }: {
    # Create VST plugin symlinks for audio production
    system.activationScripts.lsp-plugins-vst = ''
      mkdir -p /home/vera/.vst /home/vera/.vst3
      ln -sf ${pkgs.lsp-plugins}/lib/vst /home/vera/.vst/lsp-plugins
      ln -sf ${pkgs.lsp-plugins}/lib/vst3 /home/vera/.vst3/lsp-plugins
    '';
  };
}
