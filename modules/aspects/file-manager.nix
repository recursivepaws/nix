{
  den.aspects.file-manager = {
    nixos =
      { pkgs, lib, ... }:
      let
        # "image" "eog.desktop" [ "png" "jpeg" ] -> { "image/png" = "eog.desktop"; ... }
        assoc =
          prefix: app: subtypes:
          lib.genAttrs (map (t: "${prefix}/${t}") subtypes) (_: app);
      in
      {
        services.gvfs.enable = true;
        environment.systemPackages = with pkgs; [
          nautilus
          file-roller
        ];
        xdg.mime.defaultApplications = lib.mergeAttrsList [
          {
            "inode/directory" = "org.gnome.Nautilus.desktop";
            "application/pdf" = "google-chrome.desktop";
          }
          (assoc "image" "org.gnome.eog.desktop" [
            "png"
            "jpeg"
            "gif"
            "webp"
            "tiff"
            "bmp"
            "svg+xml"
            "heif"
            "avif"
          ])
          (assoc "video" "vlc.desktop" [
            "mp4"
            "mpeg"
            "webm"
            "quicktime"
            "x-matroska"
            "x-msvideo"
            "x-flv"
          ])
          (assoc "audio" "vlc.desktop" [
            "mpeg"
            "flac"
            "ogg"
            "x-wav"
            "x-m4a"
            "aac"
            "opus"
          ])
          (assoc "application" "org.gnome.FileRoller.desktop" [
            "zip"
            "x-tar"
            "gzip"
            "x-bzip2"
            "x-xz"
            "zstd"
            "x-7z-compressed"
            "vnd.rar"
          ])
        ];
      };
  };
}
