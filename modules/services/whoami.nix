{ ... }:
let
  name = "whoami";
in
{
  flake.modules.nixos."${name}" =
    { config, ... }:
    {
      services.${name} = {
        enable = true;
      };

      homelab.services."${name}" = {
        traefik.service.port = config.services."${name}".port;
        traefik.middlewares = [ "tinyauth" ];
      };
    };
}
