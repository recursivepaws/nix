{ den, ... }:
let
  # Wine fixes rekordbox 7 needs, vendored from MrNorm/rekordbox-wine so they survive the repo moving.
  # 0001-0010 are theirs verbatim, 0011 renders their build-wineusb-hcd.sh splice as a plain patch, and 0012 is lacamar/wine-arm64ec-rpm's Wayland equivalent of their X11-only 0005.
  patchDir = ./patches/rekordbox;

  # A component that built unpatched loads fine and behaves as stock, so assert on marker strings.
  markers = {
    "x86_64-windows/dxgi.dll" = "RBW-PATCH";
    "x86_64-windows/mmdevapi.dll" = "RBW-MMDEV";
    "x86_64-windows/setupapi.dll" = "PhysicalDeviceObjectName";
    "x86_64-windows/mountmgr.sys" = "RBW-VOLNODE";
    "x86_64-windows/wineusb.sys" = "RBW-USBHCD";
    "x86_64-unix/winealsa.so" = "RBW-EVENT3";
    "x86_64-unix/winex11.so" = "RBW-POPUP";
    "x86_64-unix/winewayland.so" = "RBW-POPUP-WL";
    "x86_64-unix/mountmgr.so" = "RBW-REMOVABLE";
    "x86_64-unix/wineusb.so" = "RBW-USBHCD";
  };

  overlay = final: prev: {
    # WARN: a separate attribute, not an override of the system-wide wine-staging from windows-vst.nix - yabridge is pinned to its own Wine and must not move.
    # unstableFull (vanilla wow64) because the series is authored against pristine winehq 11.16 and upstream says it applies to nothing else.
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
        # Not MrNorm's - they run KWin on X11. Same bug as their 0005, in the Wayland driver.
        "${patchDir}/0012-winewayland-popup-not-managed.patch"
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

        # Wine backs the Windows HID stack with /dev/hidraw*, root-only by default, so the controller is invisible and its MIDI port never opens. Vendor-wide 2b73 covers the FLX4 and the DDJ-400.
        # WARN: the 60- prefix is load-bearing - uaccess is acted on by 73-seat-late.rules, so anything above 73 tags too late, which rules out services.udev.extraRules and its hardcoded 99-local.rules.
        services.udev.packages = [
          (pkgs.writeTextFile {
            name = "pioneer-ddj-udev-rules";
            destination = "/lib/udev/rules.d/60-pioneer-ddj.rules";
            text = ''
              KERNEL=="hidraw*", ATTRS{idVendor}=="2b73", MODE="0660", GROUP="audio", TAG+="uaccess"
            '';
          })

          # Wine's mountmgr names a filesystem by reading the boot sector off the raw device node (root:disk 0660) and falls back to NTFS when that open fails, so rekordbox rejects a FAT32 stick as "formatted with an unsupported file system".
          # Scoped to ID_BUS=usb rather than joining `disk`, which would also expose the internal NVMe's raw LUKS container. Same 60- prefix constraint as above.
          (pkgs.writeTextFile {
            name = "usb-block-uaccess-udev-rules";
            destination = "/lib/udev/rules.d/60-usb-block-uaccess.rules";
            text = ''
              SUBSYSTEM=="block", ENV{ID_BUS}=="usb", TAG+="uaccess"
            '';
          })
        ];
      };

    homeManager =
      {
        pkgs,
        lib,
        config,
        user,
        ...
      }:
      let
        wine = pkgs.wine-rekordbox;

        # One source of truth, so the launcher and the diagnostic wrapper below
        # cannot drift onto different prefixes.
        defaultPrefix = "$HOME/.local/share/rekordbox-wine";

        # WARN: do not bump without re-testing - 7.2.19 crashes before showing a window on two machines and on stock wine-staging too, so it is rekordbox-vs-Wine, not our patches.
        # Only the input is pinned; the install stays imperative because rekordbox updates itself and writes registry keys and its own install dir at runtime. Stamp URLs come from SpecterShell/Dumplings.
        rekordboxVersion = "7.2.18";
        rekordboxInstaller = pkgs.fetchzip {
          url = "https://cdn.rekordbox.com/files/20260805131857/Install_rekordbox_x64_7_2_18.zip";
          hash = "sha256-Ro16UqT+AFjtVmSqvYVMMY7vb7azMtmGYkBTtJOMkqg=";
          # The zip's single entry is the .exe itself, so there is no root to strip.
          stripRoot = false;
        };

        # Idempotent rather than declarative: wineboot writes a mutable tree, so this creates the prefix once then runs whatever rekordbox.exe it finds.
        # No WINEDLLOVERRIDES=dxgi=n like upstream's launcher - that is an Arch workaround for an unpatched system Wine, and our builtin dxgi is already patched.
        rekordbox = pkgs.writeShellApplication {
          name = "rekordbox";
          runtimeInputs = [
            wine
            pkgs.winetricks
            pkgs.findutils
          ];
          text = ''
            export WINEPREFIX="''${WINEPREFIX:-${defaultPrefix}}"
            export WINEARCH=win64

            # Virtual desktop implies X11 through xwayland-satellite: a Wine virtual desktop only exists under winex11.drv, and `explorer /desktop=` on winewayland maps nothing.
            # One X window keeps JUCE 8's popups inside Wine where a tiling compositor cannot reposition them, at the cost of compositor scaling (the knob there is Xft.dpi, not LogPixels); RB_DESKTOP=off trades that for native Wayland toplevels and fractional scaling.
            if [ "''${RB_DESKTOP:-}" = "off" ]; then
              # Leaving DISPLAY set lets Wine fall back to the session's xwayland-satellite silently.
              unset DISPLAY
              if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
                echo "no WAYLAND_DISPLAY — this needs to run inside the Wayland session" >&2
                exit 1
              fi
              driver=wayland
            else
              if [ -z "''${DISPLAY:-}" ]; then
                echo "no DISPLAY — the virtual desktop needs xwayland-satellite" >&2
                echo "  (or run with RB_DESKTOP=off for native Wayland windows)" >&2
                exit 1
              fi
              driver=x11
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

            # explorer.exe reads this key to pick the driver, so record the choice in the prefix rather than leaning on whether DISPLAY is set.
            # A prefix left on wayland would otherwise quietly drop the virtual desktop.
            wine reg add 'HKCU\Software\Wine\Drivers' /v Graphics /t REG_SZ /d "$driver" /f

            # Vulkan, not OpenGL: radeonsi exhausts its 32-bit GPU VA window over a long session (ac_drm_va_range_alloc with AMDGPU_VA_RANGE_32_BIT, not memory pressure) and takes rekordbox down with it, while RADV allocates from the 64-bit range.
            # Registry rather than WINE_D3D_CONFIG so the choice is visible in winecfg; RB_RENDERER=gl restores the old behaviour for a run.
            wine reg add 'HKCU\Software\Wine\Direct3D' /v renderer /t REG_SZ \
              /d "''${RB_RENDERER:-vulkan}" /f

            # The renderer key alone is not enough: rekordbox is two GPU clients, and rekordboxAgent.exe is Electron whose --type=gpu-process goes through OpenGL regardless of wined3d, back into the same 32-bit VA window.
            # LIBGL_ALWAYS_SOFTWARE is GL/EGL only, so rekordbox.exe keeps wined3d-on-RADV and only the mostly-idle agent drops to llvmpipe (RB_SOFTWARE_GL=0 opts out).
            if [ "''${RB_SOFTWARE_GL:-1}" != "0" ]; then
              export LIBGL_ALWAYS_SOFTWARE=1
            fi

            # WARN: setting HKCU\Software\Wine\Explorer\ShowSystray to 0 to lose the 111x35 tray sliver deadlocks rekordbox on the splash screen, every thread blocked on ntdll's loader_section.
            # Bisected 2026-10-07; the tray is hidden compositor-side instead, see the explorer.exe window-rule in niri.nix.

            # NOTE: no DPI knob - Wine 11.16 has no per-monitor DPI, so LogPixels is reset to 96 before the app reads it and wp_fractional_scale_v1 only sets buffer scale.
            # Tried on X11 and Wayland at 144 and 192: no observable difference.

            # --install with no argument uses the pinned installer; pass a path to try another build without editing Nix.
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

            # Prefer the pinned version over the newest, unlike upstream's launcher: rekordbox updates itself from inside the prefix, so "newest" can silently become the broken 7.2.19.
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

            # The bundled updater is a separate program (app-id "upmgr rekordbox.exe") offering the broken 7.2.19, which the installer pin cannot prevent.
            # Renamed rather than deleted so it is one mv to undo, and re-applied every launch because reinstalling puts it back.
            upmgr="$(dirname "$app")/Upmgr rekordbox.exe"
            if [ -f "$upmgr" ]; then
              echo "disabling rekordbox's bundled updater (it offers the broken 7.2.19)"
              mv -- "$upmgr" "$upmgr.disabled"
            fi

            # One X window holding every Wine window, per the driver comment above.
            # Size with RB_DESKTOP=WIDTHxHEIGHT, or RB_DESKTOP=off for native Wayland toplevels; `rekordbox-probe` tells you whether they stayed on screen.
            if [ "''${RB_DESKTOP:-}" = "off" ]; then
              wine "$app" "$@"
            else
              wine explorer "/desktop=rekordbox,''${RB_DESKTOP:-2560x1400}" "$app" "$@"
            fi
          '';
        };

        # WARN: namespaced, never plain `wine` in home.packages - the HM profile precedes /run/current-system/sw/bin, so it would shadow the wine-staging windows-vst.nix installs for yabridge.
        # Still needs to be reachable for `rekordbox-wine winecfg`, `regedit`, and `wineboot -k` on a wedged prefix.
        rekordbox-wine = pkgs.writeShellApplication {
          name = "rekordbox-wine";
          runtimeInputs = [ wine ];
          text = ''
            export WINEPREFIX="''${WINEPREFIX:-${defaultPrefix}}"
            exec wine "$@"
          '';
        };

        # The failure mode here is silent and fast - a window maps and is gone in milliseconds - so "it looked fine" is not evidence.
        # Records niri's event stream and a Wine +win trace, and exits non-zero unless a rekordbox toplevel survived 8 seconds.
        rekordbox-probe = pkgs.writeShellApplication {
          name = "rekordbox-probe";
          # niri comes from the session PATH, which writeShellApplication keeps:
          # the point is to talk to the compositor that is actually running.
          runtimeInputs = [
            rekordbox
            pkgs.python3
          ];
          text = ''
                        secs="''${1:-30}"
                        dir=$(mktemp -d /tmp/rekordbox-probe.XXXXXX)
                        echo "probing for ''${secs}s, logs in $dir"

                        # Monotonic stamps: wall clock would drift against the Wine trace.
                        python3 -c '
            import subprocess, sys, time
            t0 = time.monotonic()
            p = subprocess.Popen(["niri", "msg", "--json", "event-stream"],
                                 stdout=subprocess.PIPE, text=True)
            for line in p.stdout:
                sys.stdout.write(f"{time.monotonic() - t0:.3f} {line}")
                sys.stdout.flush()
            ' > "$dir/niri.log" 2>/dev/null &
                        niri_pid=$!
                        # shellcheck disable=SC2064
                        trap "kill $niri_pid 2>/dev/null || true" EXIT

                        rekordbox > "$dir/wine.log" 2>&1 &
                        app_pid=$!

                        sleep "$secs"
                        kill "$niri_pid" 2>/dev/null || true

                        echo
                        python3 ${./rekordbox-probe.py} "$dir/niri.log"
                        rc=$?

                        echo
                        echo "rekordbox still running as $app_pid; logs kept in $dir"
                        exit $rc
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
          rekordbox-probe
        ];

        # The installer's own menu entry cannot work: winemenubuilder writes `wine <the .lnk>`, which picks up the unpatched system wine-staging and skips the launcher's prefix setup. Hence an absolute store path.
        # The icon prefix is derived from the install path, not random (7.2.18 is always EA77), so pinning the version pins the icon.
        xdg.enable = true;
        xdg.desktopEntries.rekordbox = {
          name = "rekordbox";
          exec = lib.getExe rekordbox;
          terminal = false;
          icon = "EA77_rekordbox.0";
          categories = [
            "AudioVideo"
            "Audio"
          ];
          # The virtual desktop is explorer.exe's window, not rekordbox's, so that is the app-id the compositor sees.
          # RB_DESKTOP=off instead gives per-window toplevels under "rekordbox.exe" and "upmgr rekordbox.exe"; the installer's own entry says "rekordbox", which matches neither.
          settings.StartupWMClass = "explorer.exe";
        };

        # winemenubuilder regenerates a broken launcher entry plus "Uninstall rekordbox 7" clutter on every install, so drop them on every activation.
        # Scoped to this subtree only: Pioneer/FwUpdateManager beside it is the DDJ firmware updater and is worth keeping.
        home.activation.pruneRekordboxWineMenu = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run rm -rf "${config.xdg.dataHome}/applications/wine/Programs/rekordbox"
        '';

        programs = lib.optionalAttrs (user.hasAspect den.aspects.niri) {
          niri.settings.window-rules = [
            # Wine's systray, a 111x35 untitled window.
            # Tiled rather than floating so it is a narrow column you scroll past instead of hovering over rekordbox.
            {
              matches = [
                {
                  app-id = "^explorer\\.exe$";
                  title = "^$";
                }
              ];
              open-floating = false;
              open-focused = false;
            }
            # Safety net for JUCE 8's drop-shadow slivers: Wine used to hand each over as a toplevel, and focus landing on a 1px window left the app unable to accept input.
            # Patch 0012 makes them subsurfaces, so this should match nothing - kept because it is free and the failure it guards is silent.
            {
              matches = [
                {
                  app-id = "^rekordbox\\.exe$";
                  title = "^$";
                }
                {
                  app-id = "^upmgr rekordbox\\.exe$";
                  title = "^$";
                }
              ];
              open-floating = true;
              open-focused = false;
            }
          ];
        };
      };
  };
}
