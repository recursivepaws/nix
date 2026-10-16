{ den, ... }:
{
  # Realtime limits ride along with the audio-production aspects, not defaults.
  den.aspects.bitwig-studio.includes = [ den.aspects.realtime-audio ];
  den.aspects.windows-vst.includes = [ den.aspects.realtime-audio ];
  den.aspects.dj.includes = [ den.aspects.realtime-audio ];

  den.aspects.realtime-audio.nixos = {
    security.pam.loginLimits = [
      # yabridge needs to lock its shared memory buffers.
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }

      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }

      {
        domain = "@audio";
        item = "nice";
        type = "-";
        value = "-19";
      }
    ];
  };
}
