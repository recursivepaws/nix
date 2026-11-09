{
  # Desktop aspects (niri, fonts, gtk, GUI apps) gate on host.desktop; servers set it false.
  den.schema.host =
    { lib, ... }:
    {
      options.desktop = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };

  den.hosts.x86_64-linux = {
    hericium.users = {
      vera = { };
      work = { };
    };
    amanita.users = {
      # vera = { };
      work = { };
    };
    ampulex.users = {
      vera = { };
    };
    barkstation = {
      desktop = false;
      users.vera = { };
    };
  };
}
