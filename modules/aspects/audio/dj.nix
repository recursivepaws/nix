{
  den.aspects.dj = {
    nixos =
      { pkgs, ... }:
      {
        # Mixxx's udev rule grants non-root hidraw access to the DDJ-FLX4
        services.udev.packages = [ pkgs.mixxx ];
        # JACK backend, so Mixxx doesn't fight pipewire for exclusive hw access
        services.pipewire.jack.enable = true;
      };

    homeManager =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      let
        # Mixxx can import a rekordbox USB but has never been able to write one
        # (mixxxdj/mixxx#9463, open since 2018). baken writes the legacy
        # export.pdb + PIONEER/USBANLZ format a CDJ reads, straight from a
        # rekordbox XML — no rekordbox, no Wine. --generate-analysis computes
        # the waveforms for tracks rekordbox never touched; grid and cues come
        # from the XML.
        baken = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
          pname = "baken";
          version = "4.4.0";

          src = pkgs.fetchFromGitHub {
            owner = "M-Igashi";
            repo = "baken";
            tag = "v${finalAttrs.version}";
            hash = "sha256-WX+VfNesWJB8ALMOX/uDnXSzeEEp7UVYnOvug+XtE/Q=";
          };

          cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";

          nativeBuildInputs = [ pkgs.makeWrapper ];

          # Only the transcode paths (cdjsafe, headroom, --cdjsafe) shell out to
          # ffmpeg/ffprobe; expressport itself decodes in-process via symphonia.
          postInstall = ''
            wrapProgram $out/bin/baken --prefix PATH : ${lib.makeBinPath [ pkgs.ffmpeg ]}
          '';

          meta = {
            description = "Bake'n Deck — writes a CDJ-readable rekordbox USB export from a rekordbox XML";
            homepage = "https://github.com/M-Igashi/baken";
            license = lib.licenses.mit;
            mainProgram = "baken";
          };
        });
        # rbxport builds its own rekordbox-format library — verified: with no
        # rekordbox installed it logs "no library here; offering to make one"
        # and creates master.db plus share/PIONEER/{Artwork,USBANLZ}. It has its
        # own beatgrid/key analysis engine, and is the only Linux-native writer
        # of the OneLibrary format the CDJ-3000X/XDJ-AZ/OPUS-QUAD generation
        # requires. Prerelease: back up the library before trusting it.
        #
        # It hardcodes its library at ~/Library/Pioneer/rekordbox (a macOS path
        # layout, on Linux). RBXPORT_OPTIONS can't move it — that points at an
        # existing rekordbox install's options.json, whose `dp` key is base64
        # SQLCipher key material, not a path. So redirect with a symlink below;
        # rbxport follows it transparently.
        rbxport = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "rbxport";
          version = "1.0.0-rc.13";

          src = pkgs.fetchurl {
            url = "https://download.rbxport.com/rbxport-${finalAttrs.version}-linux-x86_64.deb";
            hash = "sha256-pPUYukKpBLbPWwtcokRjrTHc4jnFArMBwQh+YeptvRk=";
          };

          nativeBuildInputs = with pkgs; [
            dpkg
            autoPatchelfHook
            wrapGAppsHook3
          ];

          buildInputs = with pkgs; [
            alsa-lib
            cairo
            dbus
            gdk-pixbuf
            glib
            gtk3
            libsoup_3
            webkitgtk_4_1
            stdenv.cc.cc.lib
          ];

          unpackCmd = "dpkg-deb -x $src .";
          sourceRoot = ".";

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r usr/bin usr/share $out/
            runHook postInstall
          '';

          meta = {
            description = "Fast rekordbox library manager and USB/OneLibrary exporter";
            homepage = "https://rbxport.com/";
            license = lib.licenses.unfree;
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
            platforms = [ "x86_64-linux" ];
            mainProgram = "rbxport";
          };
        });
      in
      {
        home.packages = [
          baken
          rbxport

          # QT_QPA_PLATFORMTHEME=gtk3 makes Mixxx abort.
          # TODO: maybe fix upstream?
          (pkgs.symlinkJoin {
            name = "mixxx-${pkgs.mixxx.version}";
            paths = [ pkgs.mixxx ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/mixxx --prefix XDG_DATA_DIRS : \
                "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
            '';
          })
        ];

        # Keep rbxport's library under XDG instead of ~/Library. The directory
        # must exist before the symlink is useful, so create it first.
        # If a real ~/Library/Pioneer/rekordbox already holds data, home-manager
        # refuses rather than clobbering it — move it into place by hand.
        home.file."Library/Pioneer/rekordbox".source =
          config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/rbxport/rekordbox";

        home.activation.rbxportLibraryDir = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
          run mkdir -p "${config.xdg.dataHome}/rbxport/rekordbox"
        '';
      };
  };
}
