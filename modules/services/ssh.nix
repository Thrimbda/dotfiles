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
      kbdInteractiveAuthentication = false;
      passwordAuthentication = false;
    };

    user.openssh.authorizedKeys.keys =
      if config.user.name == "c1"
      then ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDnv1tjzz6WPi9+0beYseH2q+XsklTZGV9DR/6IUSazIClDVnSybWjfILLyDJSMIg+t7HUFM6tp8m23eET2ZIGdeg2+zUci2xP7szx4ZVGEfPZ2yKRPPcGwfAgCftbjQAv4xehPqC5Drd9t3r+jnvlJPE5FhsbRzdbedJTeQoSY14fw32kRZE20jfYWSGoN4YB+pw/ycFet812x8Wh1yRj/VR0J/lkT67+SEPXXksdP7N+GWj7rKjbaeuCcr15b+xPoru/Bkgwq3NrlUTXY4DMbG6xMEdTDhlPz4CaUpvqrPYtnKTiG6VP5WUdVq7E0f4VCwKBvTk0BPeuT8noQm7onk2afphwAfo/wRkvc6/m8tucJBqs3LGUZLrcz5vE+jCMXzuyK6tmhziOGExEnn9iUC4dgBUwdOzVE3eFRCS8whcMp28tz2wLF3WiKdUeg8madPLL44xomCPIWRi7y+g82ErUy+4qa+wsVrUFF14y+esuDoeXTSZ+Wo6bu5s6f+Xi0oOe12t42iPyc2MUbZUVGiKlqB+BxiEiZTnE1c7dp+Ph91JaD/plr4EzpuDo0eGBwZEkBSq46nMidnUyubt+fJmxf7ruHf3cz88Y+YBkZPFwzd4vgjw9No3OmziSiCbBa9blkkQ7npX+r1l9cOEcfGgBa4Kvi7GX1WXqJziHMjw== wangsiyuan.wangsy@bytedance.com"]
      else [];
  };
}
