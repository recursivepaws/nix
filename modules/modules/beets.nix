{
  # beets CLI + config for the ~/Music/IPOD library.
  # Config reconstructed from ~/Music/IPOD/{config.yaml,context.md,MAINTENANCE.md}.
  den.aspects.beets = {
    homeManager =
      { pkgs, ... }:
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
              minwidth = 1000;
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

            # Downsample above-CD-quality to 16-bit/44.1kHz FLAC (one-way).
            # Run via `beet convert --keep-new`, not auto.
            convert = {
              auto = true;
              format = "flac";
              formats.flac = {
                command = "${pkgs.ffmpeg}/bin/ffmpeg -i $source -y -vn -ar 44100 -sample_fmt s16 -acodec flac -compression_level 8 $dest";
                extension = "flac";
              };
              # skip files already at or below CD quality
              no_convert = "samplerate:..44100 bitdepth:..16";
              never_convert_lossy_files = true;
              embed = false;
              # --keep-new backs up originals here
              # dest = "~/Music/beets-high-resolution-backup";
              delete_originals = false;
              threads = 4;
            };
          };
        };

        # Also on user PATH for manual ffmpeg/flac steps in MAINTENANCE.md.
        home.packages = with pkgs; [
          ffmpeg
          imagemagick
          flac
          mp3val
        ];
      };
  };
}
