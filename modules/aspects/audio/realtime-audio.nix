{ den, ... }:
{
  # Realtime limits ride along with the audio-production aspects, not defaults.
  den.aspects.bitwig-studio.includes = [ den.aspects.realtime-audio ];
  den.aspects.windows-vst.includes = [ den.aspects.realtime-audio ];
  den.aspects.dj.includes = [ den.aspects.realtime-audio ];

  den.aspects.realtime-audio.nixos = {
    # Fixes yabridge memlock warnings and enables low-latency audio
    security.pam.loginLimits = [
      # Unlimited memory locking for audio group
      # This allows yabridge to lock shared memory buffers
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }

      # High realtime priority for audio group
      # Allows audio applications to run with realtime scheduling
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }

      # Allow nice priority adjustment for audio group
      # Enables fine-tuning of process priorities
      {
        domain = "@audio";
        item = "nice";
        type = "-";
        value = "-19";
      }
    ];
  };
}
