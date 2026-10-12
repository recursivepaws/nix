{ den, ... }:
let
  # Wine fixes rekordbox 7 needs, from MrNorm/rekordbox-wine. Vendored rather
  # than fetched: upstream is one author, and we want this reproducible if the
  # repo moves. 0001-0010 are theirs verbatim; 0011 is their
  # bin/build-wineusb-hcd.sh splice of rbw-usbhcd.c into wineusb.c, rendered as
  # an ordinary patch so the build applies a plain series. 0012 is not theirs:
  # they target KWin on X11, so winewayland carries the same bug unfixed, and
  # the fix for it comes from lacamar/wine-arm64ec-rpm instead.
  patchDir = ./patches/rekordbox;

  # Each patched component carries a marker string. A component that silently
  # built unpatched loads fine and simply behaves as though stock - the failure
  # mode upstream says it has paid for repeatedly - so assert on them.
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
        # Not from MrNorm: they run KWin on X11, so winewayland was never in
        # their path. Same problem their 0005 fixes, in the Wayland driver;
        # the predicate is lacamar/wine-arm64ec-rpm's. See the patch header.
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

        # rekordbox finds a controller through the Windows HID stack, which Wine
        # backs with /dev/hidraw* - root-only by default, so under Wine the
        # controller is invisible and its MIDI port never opens. Vendor-wide
        # (2b73), so this covers the FLX4 as well as the DDJ-400.
        #
        # The 60- prefix is load-bearing: systemd acts on the uaccess tag in
        # 73-seat-late.rules, so a rule numbered above 73 tags too late and no
        # ACL is ever granted. Upstream hit this exact bug writing it as 99-.
        #
        # So this CANNOT use services.udev.extraRules - that option hardcodes
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

          # Wine's mountmgr names a volume's filesystem by reading the boot
          # sector off the raw device node, not from the mount. The node is
          # root:disk 0660 and we are not in `disk`, so the open fails
          #
          #   get_volume_device_info Failed to open /dev/sda1, err 5
          #
          # and mountmgr falls back to reporting NTFS. rekordbox then refuses
          # the stick with "formatted with an unsupported file system", listing
          # the FAT/HFS+/exFAT set - on a drive that is already FAT32. The
          # mounted path stays browsable throughout (udisks2 mounts it
          # uid=1000), so only the format probe is affected, which is what makes
          # this look like a formatting problem rather than a permissions one.
          #
          # This is the other half of patch 0006: that patch fixed the drive
          # being reported DRIVE_FIXED, and its header records this filesystem
          # misreport as the packaging matter it deliberately left alone.
          #
          # Scoped to ID_BUS=usb rather than adding the user to `disk`: `disk`
          # would also hand over the raw LUKS container on the internal NVMe.
          # Same 60- prefix constraint as above.
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

        # PINNED TO 7.2.18 DELIBERATELY - do not "update" this to the current
        # release without re-testing. Measured here 2026-10-05:
        #
        #   7.2.19 crashes before showing a window, every time, identically on
        #   two machines (integrated RDNA 3.5 and discrete Navi 24) AND on stock
        #   unpatched wine-staging 11.14 as well as our patched 11.16 - so it is
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
        # directory which rekordbox.com no longer advertises - the download page
        # only ever lists the current release. These stamps come from
        # SpecterShell/Dumplings, a winget bot that logs every release URL.
        #
        # stripRoot = false because the zip's single entry is the .exe itself,
        # not a directory, so there is no root to strip.
        #
        # Only the INPUT is pinned here. The install stays imperative on purpose:
        # rekordbox updates itself from inside the prefix, its NSIS installer
        # writes registry keys (not just files) into system.reg/user.reg, and it
        # writes into its own install dir at runtime - none of which survives
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
        # overlaying onto an unpatched system Wine - our builtin dxgi is already
        # patched, so the builtin is what we want.
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

            # VIRTUAL DESKTOP ON X11 BY DEFAULT - and the driver choice is not
            # free: a Wine virtual desktop only exists under winex11.drv.
            #
            # Measured 2026-10-12 on winewayland.drv: `explorer /desktop=` does
            # create the desktop window ("rbtest - Wine Desktop" in a +win
            # trace), then
            #
            #   err:system:NtUserChangeDisplaySettings Changing (null) display
            #     settings returned -2.
            #   err:explorer:initialize_display_settings Failed to set primary
            #     display settings.
            #
            # and no toplevel ever reaches the compositor - nothing maps. So
            # desktop mode implies X11, through the session's xwayland-satellite.
            #
            # What the two modes trade:
            #
            #  - X11 + /desktop: every Wine window lives inside ONE X window, so
            #    niri manages exactly that window and Wine handles popups
            #    internally where no compositor can touch them. This is what
            #    makes JUCE 8 behave - it wraps every popup in four 14px
            #    drop-shadow windows and tears the popup down if anything
            #    repositions one, which a tiling compositor does by definition.
            #    Cost: an X client through the satellite does not participate in
            #    compositor scaling, so on a 2880x1920 scale-1.5 output the UI
            #    renders 1:1 and comes out small. RB_DESKTOP only changes how
            #    much of the app you see, not how big its widgets are; the knob
            #    for that is the X server's Xft.dpi (winex11 reads it and
            #    overwrites LogPixels with it - which is why LogPixels alone was
            #    measured to do nothing here), set with `xrdb -merge`.
            #  - Native Wayland (RB_DESKTOP=off): popups become real xdg_popups
            #    a compositor cannot relocate behind the client's back, and Wine
            #    reads wp_fractional_scale_v1 so 1.5 becomes 150% DPI for free.
            #    Cost: every Wine window is a separate toplevel for niri to
            #    float, which is the arrangement this swapped away from.
            #
            # DISPLAY is cleared in the off path, not just ignored: the session
            # runs an xwayland-satellite on :0, and leaving DISPLAY set lets Wine
            # fall back to X11 silently, which looks like "Wayland didn't help".
            if [ "''${RB_DESKTOP:-}" = "off" ]; then
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

            # explorer.exe reads this key to pick the graphics driver. Set it
            # explicitly rather than relying on DISPLAY being set or not, so the
            # choice is recorded in the prefix and visible in winecfg. It follows
            # the mode picked above, or a prefix left on wayland would quietly
            # drop the virtual desktop.
            wine reg add 'HKCU\Software\Wine\Drivers' /v Graphics /t REG_SZ /d "$driver" /f

            # DO NOT set HKCU\Software\Wine\Explorer\ShowSystray to 0 to get rid
            # of the 111x35 tray sliver. It looks like the obvious fix and it
            # deadlocks rekordbox on the splash screen, reproducibly: every
            # thread blocks on ntdll's loader_section waiting for the one that
            # is bringing the tray up, and the app never reaches its main window.
            #
            #   err:sync:RtlpWaitForCriticalSection section ...
            #     "dlls/ntdll/loader.c: loader_section" ... blocked by 01f4
            #
            # Bisected here 2026-10-07: identical runs start fine with
            # ShowSystray=1 and hang with 0. The tray is hidden compositor-side
            # instead - see the explorer.exe window-rule in niri.nix.

            # No DPI knob here, deliberately. LogPixels does nothing under this
            # Wine: it is written, and Wine resets it to 0x60 (96) before the
            # app reads it, every launch (under x11 that reset is winex11
            # applying Xft.dpi, which is why Xft.dpi is the knob that bites and
            # LogPixels is not). The trace says why:
            # "create_window_handle DPI context 0x22 not implemented" and
            # "EnableNonClientDpiScaling (...): stub" - per-monitor DPI is not
            # implemented in 11.16, so nothing is wired to the value.
            # wp_fractional_scale_v1 is negotiated but only sets buffer scale,
            # which sharpens rendering without changing layout size. Tried on
            # both X11 and Wayland, at 144 and 192: no observable difference.

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
            # inside the prefix - so "newest" can silently become a broken
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

            # rekordbox ships its own updater as a separate program and starts it
            # alongside itself. The "update packages were found" dialog is that
            # program's window, not rekordbox's - it shows up in the compositor
            # under its own app-id, "upmgr rekordbox.exe".
            #
            # It offers 7.2.19, which is exactly the build pinned away from above
            # because it crashes before showing a window. Taking the offer would
            # quietly replace a working install with a broken one, and the pin
            # cannot prevent that: it only controls which installer we fetch, not
            # what the app does to itself afterwards.
            #
            # Renamed rather than deleted so it is one mv to undo, and a
            # reinstall restores it regardless. Re-applied every launch because
            # reinstalling puts it back. Verified: rekordbox starts normally
            # without it and no update dialog appears.
            upmgr="$(dirname "$app")/Upmgr rekordbox.exe"
            if [ -f "$upmgr" ]; then
              echo "disabling rekordbox's bundled updater (it offers the broken 7.2.19)"
              mv -- "$upmgr" "$upmgr.disabled"
            fi

            # One X window holding every Wine window, per the driver comment at
            # the top. Size it with RB_DESKTOP=WIDTHxHEIGHT, or RB_DESKTOP=off
            # for native Wayland toplevels. Either way `rekordbox-probe` is how
            # to tell whether the windows actually stayed on screen.
            if [ "''${RB_DESKTOP:-}" = "off" ]; then
              wine "$app" "$@"
            else
              wine explorer "/desktop=rekordbox,''${RB_DESKTOP:-2560x1400}" "$app" "$@"
            fi
          '';
        };

        # Namespaced on purpose. The patched Wine must NOT go into home.packages
        # as plain `wine`: home-manager's profile (~/.nix-profile/bin, PATH
        # position 8) precedes /run/current-system/sw/bin (position 13), so it
        # would shadow the wine-staging that windows-vst.nix installs for
        # yabridge - and yabridge is version-sensitive enough that
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

        # Did the windows actually stay on screen? The failure this config keeps
        # running into is silent and fast - a window maps and is gone again in
        # milliseconds - so "it looked fine" is not evidence. This launches
        # rekordbox, records niri's event stream and a Wine +win trace, and
        # exits non-zero unless a rekordbox toplevel survived 8 seconds.
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

        # The installer's own menu entry does not work, and cannot: NSIS has
        # winemenubuilder write `wine <the .lnk>`, so it gets the wine-staging on
        # /run/current-system/sw/bin (unpatched - see the overlay comment)
        # instead of our patched build, and none of the prefix setup the launcher
        # above does. Hence an absolute store path: PATH order from a desktop
        # launcher is not ours to assume.
        #
        # Icon is the one winemenubuilder extracted into ~/.local/share/icons.
        # Its prefix is derived from the install path, not random - 7.2.18 is
        # always EA77 (7.2.19 was 26A7) - so pinning the version pins the icon.
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
          # The virtual desktop is explorer.exe's window, not rekordbox's, so
          # that is the app-id the compositor sees - titled "rekordbox - Wine
          # Desktop". (Running RB_DESKTOP=off instead gives per-window
          # toplevels, where winewayland derives the app-id from the process
          # name: "rekordbox.exe", plus "upmgr rekordbox.exe" for dialogs. Both
          # measured with rekordbox-probe.) The installer's own entry says
          # "rekordbox", which matches neither.
          settings.StartupWMClass = "explorer.exe";
        };

        # Everything winemenubuilder generates for rekordbox is unwanted: its
        # launcher entry is broken (see above) and duplicates ours in the menu,
        # and the "Uninstall rekordbox 7" entries are launcher clutter. It
        # regenerates them on every install, so drop them on every activation.
        #
        # Deliberately scoped to this one subtree, not all of wine/Programs:
        # Pioneer/FwUpdateManager lives beside it and is the DDJ firmware
        # updater, which is worth keeping. Icons live under ~/.local/share/icons
        # and are untouched - the entry above points at one.
        #
        # The uninstaller itself is unaffected, it is a .exe in the prefix:
        #   rekordbox-wine "C:/Program Files/rekordbox/rekordbox <ver>/Uninstall rekordbox.exe"
        home.activation.pruneRekordboxWineMenu = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run rm -rf "${config.xdg.dataHome}/applications/wine/Programs/rekordbox"
        '';

        programs = lib.optionalAttrs (user.hasAspect den.aspects.niri) {
          niri.settings.window-rules = [
            # Wine's systray, a 111x35 window with no title. Tiled rather
            # than floating on purpose: floating, it hovers over rekordbox
            # and is in the way; tiled it is just a narrow column you scroll
            # past. It cannot be switched off Wine-side - ShowSystray=0
            # deadlocks rekordbox on its splash screen, see above.
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
            # Safety net for JUCE chrome. rekordbox is JUCE 8, which wraps
            # every popup in four drop-shadow slivers (1x1, 234x9, 9x90);
            # Wine used to hand each one over as a toplevel, niri focused the
            # newest, and focus landing on a 1px window left the app unable
            # to accept input with Mod+C closing the sliver instead.
            #
            # Wine patch 0012 fixes that at the source - they are subsurfaces
            # now and never reach the compositor - so this should match
            # nothing. It stays because it is free and the failure it guards
            # against is silent and very confusing.
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
