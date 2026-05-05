let
  age-yubikey-identity = "age1yubikey1qwtem02lwn7jpfwl5mu4jsrvty8xhv7s5vn005530apnhjpmx8r8sup2ve0";
  age-1p-identity = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINY5xZYRlbxjdw4N47VADFRSU3EeSI3Yze97F8cWGLS";
  host-hericium = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHc1lBH+WMR9uqtNaCBxheZBtQv7py+Cn9+vNaU3hmfa";
in
{
  "startup.age".publicKeys = [
    age-yubikey-identity
    age-1p-identity
    host-hericium
  ];
}
