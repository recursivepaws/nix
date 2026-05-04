let
  network = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHBh6YdnTvVsovh6jX65ub96Qls5Y4Dl/pGBOFoi9TWh";
  signing = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINY5xZYRlbxjdw4N47VADFRSU3EeSI3Yze97F8cWGLS";
  vera = [
    network
    signing
  ];

  hericium = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHc1lBH+WMR9uqtNaCBxheZBtQv7py+Cn9+vNaU3hmfa";
  computers = [
    hericium
  ];
in
{
  "user.age".publicKeys = vera;
  "startup.age".publicKeys = computers;
}
