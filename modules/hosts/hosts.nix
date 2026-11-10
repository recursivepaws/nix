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
    hericium = {
      desktop = true;
      users = {
        vera = { };
        work = { };
      };
    };
    amanita = {
      desktop = true;
      users = {
        # vera = { };
        work = { };
      };
    };
    ampulex = {
      desktop = true;
      users = {
        vera = { };
      };
    };
    barkstation = {
      desktop = false;
      users.vera = { };
    };
  };
}
