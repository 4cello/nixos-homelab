{ ... }:
let
  name = "syncthing";
in
{
  flake.modules.nixos."${name}" =
    { config, lib, ... }:
    let
      hl = config.homelab;
      configDir = "${hl.mounts.config}/${name}";
      dataDir = "${hl.mounts.fast}/personal/${name}";
    in
    {
      services.${name} = {
        inherit configDir dataDir;
        enable = true;
        user = hl.user.name;
        group = hl.group.name;
        openDefaultPorts = true;
        settings = {
          gui.insecureSkipHostcheck = true;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0755 ${hl.user.name} ${hl.group.name} - -"
        "d ${configDir} 0755 ${hl.user.name} ${hl.group.name} - -"
      ];

      homelab.services."${name}" = {
        traefik.service.port = lib.strings.toIntBase10 (
          lib.last (lib.splitString ":" config.services.${name}.guiAddress)
        );
        traefik.middlewares = [ "tinyauth" ];
      };
    };
}
