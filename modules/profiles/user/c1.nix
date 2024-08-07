{ hey, lib, config, ... }:

with lib;
let cfg = config.modules.profiles;
    username = cfg.user;
    role = cfg.role;
in mkIf (username == "c1") (mkMerge [
  {
    user.name = username;
    user.description = "Siyuan";
    i18n.defaultLocale = mkDefault "zh_CN.UTF-8";
    modules.shell.vaultwarden.settings.server = "vault.0xc1.space";

    # Be slightly more restrictive about SSH access to workstations, which I
    # only need LAN access to, if ever. Other systems, particularly servers, are
    # remoted into often, so I leave their access control to an upstream router
    # or local firewall.
    user.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICuzQAqcyK3fVxxZ4QaH65tzqO9Qh2ESphspydq0dhyf c.one@thrimbda.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKrC5k/qhfJUVkMG0Fr+RKEIf1VV9Q6eSWLcnP+NXiFR c.one@thrimbda.com"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDUK/FKFm8srCI0Xo6VJzaORPAABhTQUzRCdY7CT9V5MIuasstx4jZE7a619TipBuPcK+9qe3IUDHq22p4bm0SFBtzxbGuAoG+MSizIkjVoqCz5BmVTrw5qqsVAhQzAqDSW4IWOt1i8r+up18qOX0jcWjkXIDyWqnHwK7Vao1CGqRAuoH1cyvHZ8hK4VtjEVugTdtcLszTsFNQyxZY3FHGETRt3axzz02b7Bp8cCn+0gknKEGNXEEjekQByIkWoYbPFAdrWb97gzxqZEd4uJsM2Nw04l8TSIfVJBtqrLHCApGZ21gOFDoE+xUMd1Afwc3xlhKo9PJho4m1VzuIq5BckRbV+lACkLE7mKpKtyxAG9xyBJ+yD9QOPX1ks4+n0QJsCp8lg7svwx+JP+ZC6XhW5vYdLCfhPmJjYmTbuEQk1m4BCAqMMzhyrb3y75A7ACyPaqDcBe6kKjc0zl9HUe0+LNlf/hKdLrVYrMsFIDcJWlNu0lCTi+mLYc52DFtgRy75W6slFcwtxJEXK88FG2Q+ogIvjSzcuEaBnxDlhRn4y4v5lvZq0VDct68xhR1rb1PEjKAmnXY2e+uOhBwoqNGXMxNeGEn1Jrk8ondXb1GTJVShDUAnX2BCE1USo9ZMTYPvzyJtYZGbjK5j9/aSamhStZ2YuhChK0U/ZaGIqoRmlw== siyuan.arc@gmail.com"
    ];
  }
])
