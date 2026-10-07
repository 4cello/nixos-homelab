{ ... }:
let
  name = "bazarr";
in
{
  flake.modules.nixos."${name}" =
    { config, ... }:
    let
      hl = config.homelab;
    in
    {
      services.${name} = {
        enable = true;
        user = hl.user.name;
        group = hl.group.name;
        dataDir = "${hl.mounts.config}/${name}";
      };

      homelab.services."${name}" = {
        traefik.service.port = config.services.${name}.listenPort;
        traefik.middlewares = [ "tinyauth" ];
      };
    };
}
