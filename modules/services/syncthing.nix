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
      dataDir = "${hl.mounts.fast}/personal/home";
    in
    {
      services.${name} = {
        inherit configDir dataDir;
        enable = true;
        user = hl.user.name;
        group = hl.group.name;
        overrideDevices = false;
        overrideFolders = false;
        openDefaultPorts = true;
        settings = {
          gui.insecureSkipHostcheck = true;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0755 ${hl.user.name} ${hl.group.name} - -"
        "d ${configDir} 0755 ${hl.user.name} ${hl.group.name} - -"
      ]
      ++ (map ({ path, ... }: "d ${path} 0755 ${hl.user.name} ${hl.group.name} - -") (
        builtins.attrValues config.services.${name}.settings.folders
      ));

      homelab.services."${name}" = {
        traefik.service.port = lib.strings.toIntBase10 (
          lib.last (lib.splitString ":" config.services.${name}.guiAddress)
        );
        traefik.middlewares = [ "tinyauth" ];
      };
    };
}
