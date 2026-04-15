{ pkgs, lib, config, ... }: {
  home.packages = with pkgs; [ flatpak rsync ];

  systemd.user.services.flatpak-repo = {
    Unit = { Description = "Install Flatpaks"; };
    Install = { WantedBy = [ "default.target" ]; };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "install-flatpaks" (''
        ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '' + lib.strings.concatMapStringsSep "\n"
        ({ package, source ? "flathub" }:
          "${pkgs.flatpak}/bin/flatpak install --user -y ${source} ${package}") [
            { package = "com.github.tchx84.Flatseal"; }
            { package = "hu.irl.cameractrls"; }
            { package = "com.fastmail.Fastmail"; }
            { package = "com.core447.StreamController"; }
            { package = "be.alexandervanhee.gradia"; }
            { package = "com.spotify.Client"; }
            { package = "com.bitwig.BitwigStudio"; }
            { package = "org.jellyfin.JellyfinDesktop"; }
          ] + "\n" + ''
            mkdir -p ~/.local/share/applications/
            mkdir -p ~/.local/share/icons/

            ln -sf ~/.local/share/flatpak/exports/share/applications/*.desktop ~/.local/share/applications/
            rsync -av --force ~/.local/share/flatpak/exports/share/icons/* ~/.local/share/icons/
            flatpak override --user \
              --env=NIX_PROFILES="$NIX_PROFILES" \
              --env=LD_LIBRARY_PATH="/run/current-system/sw/lib" \
              --filesystem=/nix/store:ro \
              --filesystem=/run/current-system:ro \
              --filesystem=~/.nix-profile:ro \
              --filesystem=~/.local/share/yabridge \
              --filesystem=~/.vst \
              --filesystem=~/.vst3 \
              --filesystem=~/.local/share/windows-vst \
              com.bitwig.BitwigStudio
          '');
    };
  };
}
