{
  # beets CLI + config for the ~/Music/IPOD library.
  # Config reconstructed from ~/Music/IPOD/{config.yaml,context.md,MAINTENANCE.md}.
  den.aspects.beets = {
    homeManager =
      { config, pkgs, ... }:
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

        # Overlay for `beet -c`: one folder per playlist under ~/Music/playlists,
        # which mpd-playlists turns into MPD stored playlists.
        playlistsConfig = (pkgs.formats.yaml { }).generate "beets-playlists.yaml" {
          directory = "~/Music/playlists";
          library = "~/Music/playlists/musiclibrary.db";
          # source_path maps each new file back to its old path, for repointing rekordbox.
          plugins = config.programs.beets.settings.plugins ++ [ "importsource" ];
          paths = {
            default = "$playlist/$artist - $title";
            comp = "$playlist/$artist - $title";
            singleton = "$playlist/$artist - $title";
          };
        };
        # fetchart/embedart only run for albums, and beet-pl imports singletons.
        # Resolve a cover URL per track from its data_source id, then let embedart shrink and embed it.
        beet-pl-art = pkgs.writeShellApplication {
          name = "beet-pl-art";
          runtimeInputs = with pkgs; [
            config.programs.beets.package
            curl
            ffmpeg
            jq
          ];
          text = ''
            # usage: beet-pl-art [--missing] [QUERY...]   (no query = every track)
            # --missing skips tracks that already have embedded art.
            cfg=${playlistsConfig}
            missing=0
            if [ "''${1-}" = "--missing" ]; then
              missing=1
              shift
            fi
            # archive.org is slow and MusicBrainz 503s under load; retry instead of giving up.
            get() { curl -sfL --retry 3 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 60 -A "beet-pl-art/1 ( https://beets.io/ )" "$@"; }
            img=$(mktemp -t beet-pl-art.XXXXXX)
            trap 'rm -f "$img"' EXIT
            tab=$(printf '\t')
            # shellcheck disable=SC2016
            beet -c "$cfg" ls -f "\$path$tab\$data_source$tab\$mb_trackid$tab\$deezer_track_id$tab\$spotify_track_id$tab\$artist$tab\$title" "$@" |
              while IFS="$tab" read -r path src mb dz sp artist title; do
                if [ "$missing" = 1 ] && ffprobe -v error -select_streams v -show_entries stream=codec_type -of csv=p=0 "$path" | grep -q video; then
                  continue
                fi
                url=""
                case "$src" in
                  Spotify)
                    # oEmbed hands out the 300px id prefix (00001e02); 0000b273 is the 640px one.
                    url=$(get "https://open.spotify.com/oembed?url=https://open.spotify.com/track/$sp" | jq -r '.thumbnail_url // empty' | sed 's/ab67616d00001e02/ab67616d0000b273/') || true
                    ;;
                  Deezer)
                    url=$(get "https://api.deezer.com/track/$dz" | jq -r '.album.cover_big // empty') || true
                    ;;
                  MusicBrainz)
                    mapfile -t rels < <(get "https://musicbrainz.org/ws/2/recording/$mb?inc=releases&fmt=json" | jq -r '.releases[].id' | head -5)
                    for rel in "''${rels[@]}"; do
                      u="https://coverartarchive.org/release/$rel/front-500"
                      if get -I -o /dev/null "$u"; then url=$u; break; fi
                    done
                    # MusicBrainz rate limit
                    sleep 1
                    ;;
                esac
                # Fallback: iTunes text search, accepted only when the title matches.
                if [ -z "$url" ]; then
                  term=$(jq -rn --arg t "$artist $title" '$t|@uri')
                  url=$(get "https://itunes.apple.com/search?media=music&entity=song&limit=5&term=$term" |
                    jq -r --arg t "$title" 'first(.results[] | select(.trackName | ascii_downcase | contains($t | ascii_downcase)) | .artworkUrl100) // empty' |
                    sed 's/100x100bb/600x600bb/') || true
                fi
                if [ -z "$url" ]; then
                  echo "no art: $path" >&2
                  continue
                fi
                echo "$path <- $url"
                if get -o "$img" "$url"; then
                  beet -c "$cfg" embedart -y -f "$img" "path:$path" </dev/null || echo "embed failed: $path" >&2
                else
                  echo "download failed: $path <- $url" >&2
                fi
              done
          '';
        };
      in
      {
        # Default pkgs.beets enables every plugin below and wraps
        # ffmpeg/imagemagick/flac/mp3val onto beet's PATH - no override needed.
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
              "embedart"
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

            # Embed a shrunk copy in every file; cover.jpg on disk stays full-res.
            embedart = {
              auto = true;
              maxwidth = 500;
              quality = 85;
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

            # Downsample above-CD-quality to 16-bit/44.1kHz FLAC on import, one-way.
            # max_bitrate = 1 fires should_transcode for every lossless file, and portableFlac copies CD-quality verbatim.
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

        # beet-pl import -s --set playlist=<name> <dir>
        home.shellAliases.beet-pl = "beet -c ${playlistsConfig}";

        # Also on user PATH for manual ffmpeg/flac steps in MAINTENANCE.md.
        home.packages = with pkgs; [
          beet-pl-art
          ffmpeg
          imagemagick
          flac
          mp3val
          sox
        ];
      };
  };
}
