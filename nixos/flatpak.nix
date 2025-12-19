{ pkgs, lib, ... }: {
  services.flatpak = { enable = true; };
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '' + lib.strings.join "\n" (map ({ package, source ? "flathub" }:
      "flatpak install -y ${source} ${package}") [
        { package = "hu.irl.cameractrls"; }
        { package = "com.core447.StreamController"; }
        { package = "be.alexandervanhee.gradia"; }
        { package = "com.spotify.Client"; }
      ]);
  };
}
