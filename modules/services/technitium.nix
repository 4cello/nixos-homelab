{ ... }:
let
  name = "technitium";
in
{
  flake.modules.nixos."${name}" =
    { config, ... }:
    let
      hl = config.homelab;
    in
    {
      services.technitium-dns-server = {
        enable = true;
        openFirewall = true;
      };

      homelab.services."${name}-${config.networking.hostName}" = {
        traefik.service.port = 5380;
      };
    };
}
