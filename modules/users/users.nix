{ den, ... }:
{
  den.default.user = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINY5xZYRlbxjdw4N47VADFRSU3EeSI3Yze97F8cWGLS"
    ];
  };

  den.schema.user =
    { user, lib, ... }:
    {
      options.profilePicture = lib.mkOption {
        type = lib.types.path;
        default = ../../assets/${user.userName}.png;
      };
    };
}
