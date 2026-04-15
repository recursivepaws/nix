let
  network =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHBh6YdnTvVsovh6jX65ub96Qls5Y4Dl/pGBOFoi9TWh";
  signing =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINY5xZYRlbxjdw4N47VADFRSU3EeSI3Yze97F8cWGLS";
  vera = [ network signing ];

  NyaNix =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvZ+DxqeKWXhjj35i7Fu0FYzOptNi+ui5il+kWc9Ev+";
  # ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvZ+DxqeKWXhjj35i7Fu0FYzOptNi+ui5il+kWc9Ev+ root@nixos
  computers = [ NyaNix ];
in {
  "user.age".publicKeys = vera;
  "startup.age".publicKeys = computers;
}
