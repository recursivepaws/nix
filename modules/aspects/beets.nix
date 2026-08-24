{
  # beets CLI + config for the ~/Music/IPOD library.
  # Config reconstructed from ~/Music/IPOD/{config.yaml,context.md,MAINTENANCE.md}.
  den.aspects.beets = {
    homeManager =
      { pkgs, ... }:
      let
        # max_bitrate = 1 makes beets hand every lossless file to this script;
        # the resolution decision lives here, via soxi, not in beets.
        portableFlac = pkgs.writeShellScript "portable-flac" ''
          set -euo pipefail
          src="$1"
          dst="$2"
          sr=$(${pkgs.sox}/bin/soxi -r "$src")
          bd=$(${pkgs.sox}/bin/soxi -b "$src")
          if [ "$sr" -le 44100 ] && [ "$bd" -le 16 ]; then
            cp "$src" "$dst"
          else
            target_sr=44100
            if [ "$sr" -lt 44100 ]; then
              target_sr="$sr"
            fi
            ${pkgs.sox}/bin/sox "$src" -G -b 16 -C 8 -r "$target_sr" "$dst"
          fi
        '';
      in
      {
        # Default pkgs.beets enables every plugin below and wraps
        # ffmpeg/imagemagick/flac/mp3val onto beet's PATH — no override needed.
        programs.beets = {
          enable = true;
          settings = {
            directory = "~/Music/beets";
            library = "~/Music/beets/musiclibrary.db";
            # transliterate non-ASCII paths to ASCII
            asciify_paths = true;

            paths = {
              default = "$albumartist/[$year] $album/[$track] $title";
              comp = "Compilations/[$year] $album/[$track] $title";
              singleton = "$artist/[$year] $title";
            };
            va_name = "Various Artists";

            # Reserved chars (Windows/FAT, for the iPod) -> '-'; rest are structural.
            replace = {
              "[\\\\/]" = "-";
              "[<>:\"\\|\\?\\*]" = "-";
              "[\\x00-\\x1f]" = "_";
              "^\\." = "_";
              "\\.$" = "";
              "\\s+$" = "";
              "^\\s+" = "";
            };

            import = {
              # embed tags into the files
              write = true;
              # copy into the library, keep originals
              copy = true;
              # always show track deets
              detail = true;
            };

            plugins = [
              "musicbrainz"
              "chroma"
              "deezer"
              "spotify"
              "fetchart"
              "ftintitle"
              "lastgenre"
              "lyrics"
              "convert"
              "edit"
              "scrub"
              "mbsync"
              "duplicates"
              "badfiles"
              "info"
            ];

            musicbrainz.data_source_mismatch_penalty = 0.0;

            # Move featured artists out of `artist` into the title.
            ftintitle = {
              auto = true;
              format = "feat. {0}";
            };

            fetchart = {
              auto = true;
              cover_names = [
                "cover"
                "front"
              ];
              high_resolution = true;
              # reject low-res thumbnails
              minwidth = 500;
              sources = [
                "filesystem"
                "coverart"
                "itunes"
                "amazon"
                "albumart"
              ];
            };

            lyrics = {
              auto = false;
              synced = true;
              sources = [
                "lrclib"
                "genius"
              ];
            };

            lastgenre = {
              auto = true;
              count = 4;
              separator = "; ";
              canonical = true;
            };

            # Downsample above-CD-quality to 16-bit/44.1kHz FLAC on import (one-way).
            # max_bitrate = 1 forces should_transcode to fire for every lossless file;
            # portableFlac copies CD-quality files verbatim and downsamples the rest.
            convert = {
              auto = true;
              format = "portable_flac";
              max_bitrate = 1;
              never_convert_lossy_files = true;
              # fast-path: skip true CD-quality before spawning the script
              no_convert = "samplerate:..44100 bitdepth:..16";
              embed = false;
              # `beet convert -k` moves the hi-res originals here as backup
              dest = "~/Music/beets-high-resolution-backup";
              delete_originals = false;
              threads = 4;
              formats.portable_flac = {
                command = "${portableFlac} $source $dest";
                extension = "flac";
              };
            };
          };
        };

        # Also on user PATH for manual ffmpeg/flac steps in MAINTENANCE.md.
        home.packages = with pkgs; [
          ffmpeg
          imagemagick
          flac
          mp3val
          sox
        ];
      };
  };
}
