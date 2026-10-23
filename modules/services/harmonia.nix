{ ... }:
let
  name = "harmonia";
in
{
  flake.modules.nixos."${name}" = { pkgs, ... }: {
    services."${name}" = {
      cache.enable = true;
    };

    homelab.services."${name}" = {
      traefik.service.port = 5000;
    };
  };
}
