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
        # Built off the unreleased 2.6 branch (nixpkgs stops at 2.5.6) because the stock FLX4 mapping leaves Pad FX unimplemented and ElHanko's, which does implement it, needs 2.6's Stems controls.
        # ENGINEPRIME=OFF because 2.6 pins libdjinterop 0.27.1 exact and nixpkgs has 0.26.1; rekordbox USB export goes through baken/rbxport anyway.
        mixxx = pkgs.mixxx.overrideAttrs (old: {
          version = "2.6-unstable-2026-10-06";

          src = pkgs.fetchFromGitHub {
            owner = "mixxxdj";
            repo = "mixxx";
            rev = "20fdcbfc6f16d86d495dc8da5fc515ed19b25a66";
            hash = "sha256-8Fxj+HxE+aMD0PQpqkbIATAz8G4ip4dsbYAyqfMpk2Y=";
          };

          # Upstream nixpkgs patches the 2.5 CMakeLists to accept a newer
          # libdjinterop, marked "Should be removed when bumping to 2.6.x".
          postPatch = "";

          cmakeFlags = old.cmakeFlags ++ [ "-DENGINEPRIME=OFF" ];
        });

        # Mixxx reads a rekordbox USB but has never written one (mixxxdj/mixxx#9463, open since 2018).
        # baken writes the legacy export.pdb + PIONEER/USBANLZ format straight from a rekordbox XML, with --generate-analysis filling in waveforms for tracks rekordbox never touched.
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
        # Builds its own rekordbox library from scratch (master.db + share/PIONEER/{Artwork,USBANLZ}) and is the only Linux-native writer of the OneLibrary format the CDJ-3000X/XDJ-AZ/OPUS-QUAD generation needs.
        # Packaged from the upstream .deb rather than source (chrisle/rbxport): Rust plus a pnpm/web build with a vendored rubberband.
        rbxport = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "rbxport";
          version = "1.6.0";

          src = pkgs.fetchurl {
            url = "https://download.rbxport.com/rbxport-${finalAttrs.version}-linux-x86_64.deb";
            hash = "sha256-bfxKeBfQVBT6zVB5R/RI6zNoIx2z607QnAPSsqLSuIQ=";
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
          ]
          # Without these there is no GST_PLUGIN_SYSTEM_PATH_1_0 and rbxport fails startup with "GStreamer element appsink not found"; webkitgtk needs the same plugins for media playback.
          # WARN: not gst-plugins-bad - its LV2 wrapper element makes GStreamer scan every installed LV2 plugin at registry build (884ms -> 5175ms startup here).
          ++ (with pkgs.gst_all_1; [
            gstreamer
            gst-plugins-base
            gst-plugins-good
          ]);

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
            license = lib.licenses.gpl2Plus;
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
            name = "mixxx-${mixxx.version}";
            paths = [ mixxx ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/mixxx --prefix XDG_DATA_DIRS : \
                "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
            '';
          })
        ];

        # Symlink rather than `masterDbDirectory` in rekordbox3.settings: rbxport rewrites that file itself on a library switch, so it is not ours to manage.
        # WARN: home-manager refuses if a real ~/Library/Pioneer/rekordbox already holds data - move it across by hand.
        home.file."Library/Pioneer/rekordbox".source =
          config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/rbxport/rekordbox";

        home.activation.rbxportLibraryDir = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
          run mkdir -p "${config.xdg.dataHome}/rbxport/rekordbox"
        '';
      };
  };
}
