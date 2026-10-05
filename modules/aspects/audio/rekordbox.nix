{ den, ... }:
let
  # Wine fixes rekordbox 7 needs, from MrNorm/rekordbox-wine. Vendored rather
  # than fetched: upstream is one author, and we want this reproducible if the
  # repo moves. 0001-0010 are theirs verbatim; 0011 is their
  # bin/build-wineusb-hcd.sh splice of rbw-usbhcd.c into wineusb.c, rendered as
  # an ordinary patch so the build applies a plain series.
  patchDir = ./patches/rekordbox;

  # Each patched component carries a marker string. A component that silently
  # built unpatched loads fine and simply behaves as though stock — the failure
  # mode upstream says it has paid for repeatedly — so assert on them.
  markers = {
    "x86_64-windows/dxgi.dll" = "RBW-PATCH";
    "x86_64-windows/mmdevapi.dll" = "RBW-MMDEV";
    "x86_64-windows/setupapi.dll" = "PhysicalDeviceObjectName";
    "x86_64-windows/mountmgr.sys" = "RBW-VOLNODE";
    "x86_64-windows/wineusb.sys" = "RBW-USBHCD";
    "x86_64-unix/winealsa.so" = "RBW-EVENT3";
    "x86_64-unix/winex11.so" = "RBW-POPUP";
    "x86_64-unix/mountmgr.so" = "RBW-REMOVABLE";
    "x86_64-unix/wineusb.so" = "RBW-USBHCD";
  };

  overlay = final: prev: {
    # Deliberately a separate attribute, NOT an override of the wine-staging
    # that windows-vst.nix installs system-wide: yabridge is pinned to its own
    # Wine and must not move.
    #
    # Base is unstableFull (vanilla Wine, the wow64 build) because the patch
    # series is authored against pristine winehq source, not a staged tree.
    # nixpkgs is on 11.14; the series targets 11.16 exactly and upstream is
    # explicit that it will not apply to anything else.
    wine-rekordbox = prev.wineWow64Packages.unstableFull.overrideAttrs (old: {
      pname = "wine-rekordbox";
      version = "11.16";

      src = prev.fetchurl {
        url = "https://dl.winehq.org/wine/source/11.x/wine-11.16.tar.xz";
        hash = "sha256-xm4gkDQ9zXJ/f3/S+H7gv7CxGHkMHXRat7ikw6QZfy8=";
      };

      patches = (old.patches or [ ]) ++ [
        "${patchDir}/0001-dxgi-implement-WaitForVBlank.patch"
        "${patchDir}/0002-mmdevapi-exclusive-event-streams.patch"
        "${patchDir}/0003-winealsa-exclusive-audio.patch"
        "${patchDir}/0004-winealsa-midi.patch"
        "${patchDir}/0005-winex11-popup-not-managed.patch"
        "${patchDir}/0006-mountmgr-removable-unknown-media.patch"
        "${patchDir}/0007-mountmgr-storage-descriptor-truth.patch"
        "${patchDir}/0008-setupapi-physical-device-object-name.patch"
        "${patchDir}/0009-mountmgr-volume-devnodes.patch"
        "${patchDir}/0010-wineusb-hcd-unixlib.patch"
        "${patchDir}/0011-wineusb-hcd-pe-splice.patch"
      ];

      postInstall = (old.postInstall or "") + ''
        echo "verifying patch markers..."
        ${prev.lib.concatStringsSep "\n" (
          prev.lib.mapAttrsToList (path: marker: ''
            f="$out/lib/wine/${path}"
            if [ ! -f "$f" ]; then
              echo "MISSING: $f" >&2; exit 1
            fi
            if ! ${prev.binutils}/bin/strings -a "$f" | grep -q -- '${marker}'; then
              echo "VERIFY FAILED: ${path} has no '${marker}' — built unpatched?" >&2; exit 1
            fi
            echo "  ok ${path} (${marker})"
          '') markers
        )}
      '';

      meta = (old.meta or { }) // {
        description = "Wine 11.16 with the rekordbox 7 patch series (DDJ controller audio, MIDI, USB export)";
      };
    });
  };
in
{
  den.aspects.rekordbox = {
    nixos =
      { pkgs, ... }:
      {
        nixpkgs.overlays = [ overlay ];

        # Mandatory, not optional: without ntsync wineserver burns 43-65% CPU
        # and the UI lags. In our kernel already, just not loaded by default.
        boot.kernelModules = [ "ntsync" ];

        # rekordbox finds a controller through the Windows HID stack, which Wine
        # backs with /dev/hidraw* — root-only by default, so under Wine the
        # controller is invisible and its MIDI port never opens. Vendor-wide
        # (2b73), so this covers the FLX4 as well as the DDJ-400.
        #
        # The 60- prefix is load-bearing: systemd acts on the uaccess tag in
        # 73-seat-late.rules, so a rule numbered above 73 tags too late and no
        # ACL is ever granted. Upstream hit this exact bug writing it as 99-.
        #
        # So this CANNOT use services.udev.extraRules — that option hardcodes
        # destination = /etc/udev/rules.d/99-local.rules, which is the broken
        # case. Ship a correctly-named rules file as a package instead, the same
        # way dj.nix pulls in Mixxx's own rules.
        services.udev.packages = [
          (pkgs.writeTextFile {
            name = "pioneer-ddj-udev-rules";
            destination = "/lib/udev/rules.d/60-pioneer-ddj.rules";
            text = ''
              KERNEL=="hidraw*", ATTRS{idVendor}=="2b73", MODE="0660", GROUP="audio", TAG+="uaccess"
            '';
          })
        ];
      };

    homeManager =
      { pkgs, ... }:
      let
        wine = pkgs.wine-rekordbox;

        # One source of truth, so the launcher and the diagnostic wrapper below
        # cannot drift onto different prefixes.
        defaultPrefix = "$HOME/.local/share/rekordbox-wine";

        # PINNED TO 7.2.18 DELIBERATELY — do not "update" this to the current
        # release without re-testing. Measured here 2026-10-05:
        #
        #   7.2.19 crashes before showing a window, every time, identically on
        #   two machines (integrated RDNA 3.5 and discrete Navi 24) AND on stock
        #   unpatched wine-staging 11.14 as well as our patched 11.16 — so it is
        #   rekordbox-vs-Wine, not our patches. EXCEPTION_ACCESS_VIOLATION
        #   reading 0x0 at rekordbox.exe+0x2aae1a3: a factory call leaves an
        #   out-param NULL and the caller makes a virtual call through it
        #   without checking. Ruled out as causes: GPU, Wine version/flavour,
        #   corefonts, fontconfig, disk space, win10-vs-win11.
        #
        #   7.2.18 reaches the login screen on the same prefix. It is also the
        #   build upstream verified end to end (their journal records this
        #   zip's exact content-length, 659280808).
        #
        # Old releases stay fetchable, but each needs its own opaque stamp
        # directory which rekordbox.com no longer advertises — the download page
        # only ever lists the current release. These stamps come from
        # SpecterShell/Dumplings, a winget bot that logs every release URL.
        #
        # stripRoot = false because the zip's single entry is the .exe itself,
        # not a directory, so there is no root to strip.
        #
        # Only the INPUT is pinned here. The install stays imperative on purpose:
        # rekordbox updates itself from inside the prefix, its NSIS installer
        # writes registry keys (not just files) into system.reg/user.reg, and it
        # writes into its own install dir at runtime — none of which survives
        # being pinned read-only in the store.
        rekordboxVersion = "7.2.18";
        rekordboxInstaller = pkgs.fetchzip {
          url = "https://cdn.rekordbox.com/files/20260805131857/Install_rekordbox_x64_7_2_18.zip";
          hash = "sha256-Ro16UqT+AFjtVmSqvYVMMY7vb7azMtmGYkBTtJOMkqg=";
          stripRoot = false;
        };

        # Prefix bootstrap is inherently imperative (wineboot writes a mutable
        # tree), so this is idempotent rather than declarative: it creates the
        # prefix once, then runs whatever rekordbox.exe it finds.
        #
        # Upstream's launcher forces WINEDLLOVERRIDES=dxgi=n and copies a
        # patched dxgi.dll into the prefix. That is an Arch workaround for
        # overlaying onto an unpatched system Wine — our builtin dxgi is already
        # patched, so the builtin is what we want.
        rekordbox = pkgs.writeShellApplication {
          name = "rekordbox";
          runtimeInputs = [
            wine
            pkgs.winetricks
            pkgs.findutils
            pkgs.xwayland-satellite
          ];
          text = ''
            export WINEPREFIX="''${WINEPREFIX:-${defaultPrefix}}"
            export WINEARCH=win64

            # X11 is required, not preferred: patch 0005 fixes winex11.drv, and
            # winewayland.drv wins whenever DISPLAY is unset. niri 25.08 has no
            # built-in XWayland and this config does not spawn the satellite at
            # startup, so start one here if the session has no X display.
            satellite_pid=""
            if [ -z "''${DISPLAY:-}" ]; then
              n=""
              for c in 1 2 3 4 5; do
                if [ ! -e "/tmp/.X11-unix/X$c" ]; then n="$c"; break; fi
              done
              [ -n "$n" ] || { echo "no free X display in :1-:5" >&2; exit 1; }
              echo "no DISPLAY; starting xwayland-satellite on :$n"
              xwayland-satellite ":$n" &
              satellite_pid=$!
              # shellcheck disable=SC2064
              trap "kill $satellite_pid 2>/dev/null || true" EXIT
              export DISPLAY=":$n"
              for _ in $(seq 1 50); do
                [ -e "/tmp/.X11-unix/X$n" ] && break
                sleep 0.1
              done
              [ -e "/tmp/.X11-unix/X$n" ] || { echo "xwayland-satellite did not come up" >&2; exit 1; }
            fi

            if [ ! -d "$WINEPREFIX" ]; then
              echo "creating prefix at $WINEPREFIX"
              # mscoree/mshtml disabled for the boot itself, or Wine raises a
              # download dialog that blocks forever with no wine-mono/gecko.
              WINEDLLOVERRIDES="mscoree,mshtml=d" wineboot -u
              wineserver --wait
              winetricks -q corefonts win11
            fi

            # rekordbox uses WASAPI exclusive mode on the controller. With
            # winepulse the sample-rate list comes up empty, so pin ALSA.
            wine reg add 'HKCU\Software\Wine\Drivers' /v Audio /t REG_SZ /d alsa /f

            # Not exec: that would replace the shell and skip the EXIT trap,
            # leaking the xwayland-satellite we may have started above.
            # --install with no argument uses the pinned installer; pass a path
            # to override, which is the escape hatch for trying another build
            # without editing Nix.
            if [ "''${1:-}" = "--install" ]; then
              if [ -n "''${2:-}" ]; then
                exe="$2"
                echo "installing from $exe"
              else
                exe=$(find ${rekordboxInstaller} -maxdepth 2 -name '*.exe' | head -1)
                [ -n "$exe" ] || { echo "no .exe in ${rekordboxInstaller}" >&2; exit 1; }
                echo "installing rekordbox ${rekordboxVersion} from the pinned installer"
                echo "(NSIS shows a language dialog even with /S — click through it)"
              fi
              wine "$exe"
              exit $?
            fi

            # Prefer the PINNED version, not the newest. Upstream's launcher
            # takes the newest deliberately, but that is wrong here: 7.2.19
            # crashes before showing a window, and rekordbox updates itself from
            # inside the prefix — so "newest" can silently become a broken
            # build that was never chosen.
            app="$WINEPREFIX/drive_c/Program Files/rekordbox/rekordbox ${rekordboxVersion}/rekordbox.exe"
            if [ ! -f "$app" ]; then
              app=$(find "$WINEPREFIX/drive_c/Program Files/rekordbox" \
                      -maxdepth 2 -name 'rekordbox.exe' 2>/dev/null | sort -V | tail -1)
              if [ -z "$app" ]; then
                echo "no rekordbox.exe under $WINEPREFIX" >&2
                echo "install the pinned ${rekordboxVersion} with: rekordbox --install" >&2
                exit 2
              fi
              echo "warning: pinned ${rekordboxVersion} is not installed; falling back to" >&2
              echo "         $(basename "$(dirname "$app")") — which is untested here." >&2
            fi

            # VIRTUAL DESKTOP IS REQUIRED ON niri — not a preference.
            #
            # rekordbox 7 is JUCE 8, and JUCE surrounds every popup (including
            # the login window) with four 14px drop-shadow windows. If the
            # compositor repositions ANY of them, JUCE sees the geometry change
            # and tears the whole popup down milliseconds after mapping it.
            # Measured here: the login window appeared and vanished instantly,
            # and X showed the four shadows at 14x590 / 682x14 around it.
            #
            # Upstream hit this on KWin and wrote patch 0005 to stop Wine
            # handing WS_POPUP|WS_SYSMENU windows to the WM. That is not enough
            # for a *tiling* compositor, which repositions everything it manages
            # by definition.
            #
            # /desktop puts every Wine window inside ONE X window, so niri
            # manages that single window and Wine handles popups internally
            # where no compositor can touch them. Verified: login completes and
            # the library loads.
            #
            # Override the size with RB_DESKTOP=WIDTHxHEIGHT if you want it to
            # match a different output.
            wine explorer "/desktop=rekordbox,''${RB_DESKTOP:-2560x1400}" "$app" "$@"
          '';
        };

        # Namespaced on purpose. The patched Wine must NOT go into home.packages
        # as plain `wine`: home-manager's profile (~/.nix-profile/bin, PATH
        # position 8) precedes /run/current-system/sw/bin (position 13), so it
        # would shadow the wine-staging that windows-vst.nix installs for
        # yabridge — and yabridge is version-sensitive enough that
        # custom-wine.nix keeps a 9.21 fallback for it. Regressing a working VST
        # setup for an unproven one is a bad trade.
        #
        # This still needs to be reachable, though: nothing here is proven on the
        # FLX4, so expect to want `rekordbox-wine winecfg`, `rekordbox-wine
        # regedit`, and `rekordbox-wine wineboot -k` to kill a wedged prefix.
        rekordbox-wine = pkgs.writeShellApplication {
          name = "rekordbox-wine";
          runtimeInputs = [ wine ];
          text = ''
            export WINEPREFIX="''${WINEPREFIX:-${defaultPrefix}}"
            exec wine "$@"
          '';
        };

        # One exclusive hw: open can orphan the device for the rest of the
        # session (WirePlumber ALSA error-handler bug). This is the fix.
        rekordbox-reset-audio = pkgs.writeShellApplication {
          name = "rekordbox-reset-audio";
          text = ''
            systemctl --user restart wireplumber
            echo "wireplumber restarted"
          '';
        };
      in
      {
        # home-manager has useGlobalPkgs = false here, so it builds its own
        # pkgs and needs the overlay independently of the NixOS one.
        nixpkgs.overlays = [ overlay ];

        home.packages = [
          rekordbox
          rekordbox-wine
          rekordbox-reset-audio
        ];
      };
  };
}
