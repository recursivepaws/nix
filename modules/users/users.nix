{ den, ... }:
{
  den.schema.user =
    { user, lib, ... }:
    {
      options.profilePicture = lib.mkOption {
        type = lib.types.path;
        default = ../../assets/${user.userName}.png;
      };
    };
}
