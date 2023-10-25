# fhs.nix. You know that Nix does not follow fhs spec.

{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # fhs
    (
      let base = pkgs.appimageTools.defaultFhsEnvArgs; in
      pkgs.buildFHSUserEnv (base // {
        name = "fhs";
        targetPkgs = pkgs: (
          # pkgs.buildFHSUserEnv 只提供一个最小的 FHS 环境，缺少很多常用软件所必须的基础包
          # 所以直接使用它很可能会报错
          #
          # pkgs.appimageTools 提供了大多数程序常用的基础包，所以我们可以直接用它来补充
          (base.targetPkgs pkgs) ++ [
            pkg-config
            ncurses
            # 如果你的 FHS 程序还有其他依赖，把它们添加在这里
          ]
        );
        profile = "export FHS=1";
        runScrpit = "zsh";
        extraOutputToInstall = [ pkgs.zsh "dev" ];
      })
    )
  ];
}
