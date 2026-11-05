{ den, ... }:
{
  den.aspects.crowdstrike = {
    nixos =
      { pkgs, lib, config, ... }:
      let
        # Fill from the .deb IT provides, then on the host once:
        #   nix store add --mode flat --hash-algo sha256 falcon-sensor_<version>_amd64.deb
        version = "0.0.0-00000";
        hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

        deb = pkgs.requireFile {
          name = "falcon-sensor_${version}_amd64.deb";
          inherit hash;
          message = "Add the Falcon .deb to the store first: nix store add --mode flat --hash-algo sha256 falcon-sensor_${version}_amd64.deb";
        };

        falcon = pkgs.stdenv.mkDerivation {
          pname = "falcon-sensor";
          inherit version;
          src = deb;
          nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook ];
          buildInputs = with pkgs; [ stdenv.cc.cc.lib openssl libnl zlib elfutils libbpf ];
          unpackCmd = "dpkg-deb -x $curSrc .";
          sourceRoot = ".";
          installPhase = "cp -r opt $out";
          # The sensor is signed and self-checking; stripping breaks it.
          dontStrip = true;
          meta.license = lib.licenses.unfree;
        };

        # falcond hard-codes /opt/CrowdStrike and writes state (falconstore, channel files) next to its binaries,
        # so the store tree is copied there instead of symlinked. The stamp skips the copy when the version is unchanged.
        install = pkgs.writeShellScript "falcon-install" ''
          set -eu
          d=/opt/CrowdStrike
          mkdir -p $d
          if [ "$(cat $d/.nix-source 2>/dev/null)" != "${falcon}" ]; then
            cp -r --no-preserve=mode ${falcon}/CrowdStrike/. $d/
            echo ${falcon} > $d/.nix-source
          fi
          $d/falconctl -s -f --cid="$(cat ${config.age.secrets.falcon-cid.path})" --backend=bpf
        '';
      in
      {
        # The repo is public and a CID lets anyone enrol hosts into the tenant, so it stays encrypted.
        age.secrets.falcon-cid = {
          file = ../../secrets/falcon-cid.age;
          mode = "0400";
        };

        # Transcribed from the unit shipped in the vendor .deb.
        systemd.services.falcon-sensor = {
          description = "CrowdStrike Falcon Sensor";
          wantedBy = [ "multi-user.target" ];
          unitConfig = {
            DefaultDependencies = false;
            RequiresMountsFor = [ "/opt" "/var" ];
          };
          after = [ "local-fs.target" ];
          conflicts = [ "shutdown.target" ];
          before = [ "shutdown.target" ];
          serviceConfig = {
            ExecStartPre = [ install "/opt/CrowdStrike/falconctl -g --cid" ];
            ExecStart = "/opt/CrowdStrike/falcond";
            Type = "forking";
            PIDFile = "/var/run/falcond.pid";
            Restart = "on-failure";
            RestartSec = 5;
            TimeoutStopSec = "60s";
            KillMode = "control-group";
            KillSignal = "SIGTERM";
            Delegate = true;
          };
        };
      };
  };
}
