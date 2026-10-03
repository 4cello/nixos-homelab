{ ... }:
let
  name = "radarr";
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
        settings = {
          auth = {
            method = "External";
            required = true;
          };
        };
      };

      homelab.services."${name}" = {
        traefik.service.port = config.services.${name}.settings.server.port;
        traefik.middlewares = [ "tinyauth" ];
      };
    };
}
