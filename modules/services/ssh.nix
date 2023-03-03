{ options, config, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.ssh;
in {
  options.modules.services.ssh = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        kbdInteractiveAuthentication = false;
        passwordAuthentication = false;
      };
    };

    user.openssh.authorizedKeys.keys =
      if config.user.name == "c1"
      then [
	"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDnv1tjzz6WPi9+0beYseH2q+XsklTZGV9DR/6IUSazIClDVnSybWjfILLyDJSMIg+t7HUFM6tp8m23eET2ZIGdeg2+zUci2xP7szx4ZVGEfPZ2yKRPPcGwfAgCftbjQAv4xehPqC5Drd9t3r+jnvlJPE5FhsbRzdbedJTeQoSY14fw32kRZE20jfYWSGoN4YB+pw/ycFet812x8Wh1yRj/VR0J/lkT67+SEPXXksdP7N+GWj7rKjbaeuCcr15b+xPoru/Bkgwq3NrlUTXY4DMbG6xMEdTDhlPz4CaUpvqrPYtnKTiG6VP5WUdVq7E0f4VCwKBvTk0BPeuT8noQm7onk2afphwAfo/wRkvc6/m8tucJBqs3LGUZLrcz5vE+jCMXzuyK6tmhziOGExEnn9iUC4dgBUwdOzVE3eFRCS8whcMp28tz2wLF3WiKdUeg8madPLL44xomCPIWRi7y+g82ErUy+4qa+wsVrUFF14y+esuDoeXTSZ+Wo6bu5s6f+Xi0oOe12t42iPyc2MUbZUVGiKlqB+BxiEiZTnE1c7dp+Ph91JaD/plr4EzpuDo0eGBwZEkBSq46nMidnUyubt+fJmxf7ruHf3cz88Y+YBkZPFwzd4vgjw9No3OmziSiCbBa9blkkQ7npX+r1l9cOEcfGgBa4Kvi7GX1WXqJziHMjw== wangsiyuan.wangsy@bytedance.com"
	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICuzQAqcyK3fVxxZ4QaH65tzqO9Qh2ESphspydq0dhyf c.one@thrimbda.com"
	"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDUK/FKFm8srCI0Xo6VJzaORPAABhTQUzRCdY7CT9V5MIuasstx4jZE7a619TipBuPcK+9qe3IUDHq22p4bm0SFBtzxbGuAoG+MSizIkjVoqCz5BmVTrw5qqsVAhQzAqDSW4IWOt1i8r+up18qOX0jcWjkXIDyWqnHwK7Vao1CGqRAuoH1cyvHZ8hK4VtjEVugTdtcLszTsFNQyxZY3FHGETRt3axzz02b7Bp8cCn+0gknKEGNXEEjekQByIkWoYbPFAdrWb97gzxqZEd4uJsM2Nw04l8TSIfVJBtqrLHCApGZ21gOFDoE+xUMd1Afwc3xlhKo9PJho4m1VzuIq5BckRbV+lACkLE7mKpKtyxAG9xyBJ+yD9QOPX1ks4+n0QJsCp8lg7svwx+JP+ZC6XhW5vYdLCfhPmJjYmTbuEQk1m4BCAqMMzhyrb3y75A7ACyPaqDcBe6kKjc0zl9HUe0+LNlf/hKdLrVYrMsFIDcJWlNu0lCTi+mLYc52DFtgRy75W6slFcwtxJEXK88FG2Q+ogIvjSzcuEaBnxDlhRn4y4v5lvZq0VDct68xhR1rb1PEjKAmnXY2e+uOhBwoqNGXMxNeGEn1Jrk8ondXb1GTJVShDUAnX2BCE1USo9ZMTYPvzyJtYZGbjK5j9/aSamhStZ2YuhChK0U/ZaGIqoRmlw== siyuan.arc@gmail.com"
]
      else [];
  };
}
