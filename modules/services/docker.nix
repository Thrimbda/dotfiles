{ hey, lib, options, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.docker;
    system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
    isLinux = hasSuffix "-linux" system;
in {
  options.modules.services.docker = {
    enable = mkBoolOpt false;
    package = mkOpt types.package pkgs.docker;
    # portainer.enable = mkBoolOpt false;
  };

  # Docker is only available on Linux
  config = mkIf (cfg.enable && isLinux) (mkMerge [
    {
      user.packages = with pkgs; [
        cfg.package
        docker-compose
      ];

      environment.variables = {
        DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
        MACHINE_STORAGE_PATH = "$XDG_DATA_HOME/docker/machine";
      };

      user.extraGroups = [ "docker" ];

      modules.shell.zsh.rcFiles = [ "${hey.configDir}/docker/aliases.zsh" ];

      virtualisation = {
        docker = {
          enable = true;
          package = cfg.package;
          autoPrune.enable = true;
          enableOnBoot = mkDefault false;
          # listenOptions = [];
        };
      };
    }

    # (mkIf cfg.portainer.enable {
    #   virtualisation.oci-containers.containers.portainer = {
    #     image = "...";
    #     ports = [];
    #     volumes = [];
    #   };
    # })
  ]);
}

# docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:latest
