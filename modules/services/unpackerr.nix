{ ... }:
let
  name = "unpackerr";
in
{
  flake.modules.nixos."${name}" =
    {
      config,
      lib,
      ...
    }:
    let
      hl = config.homelab;
    in
    {
      options.services."${name}" = {
        sonarr_api_key = lib.mkOption {
          type = lib.types.str;
        };
        radarr_api_key = lib.mkOption {
          type = lib.types.str;
        };
      };

      config = {
        services."${name}" = {
          enable = true;
          user = hl.user.name;
          group = hl.group.name;
          settings =
            let
              completeDir = config.services.sabnzbd.settings.misc.complete_dir;
            in
            {
              sonarr = [
                {
                  url = "http://localhost:${toString config.services.sonarr.settings.server.port}";
                  paths = [ completeDir ];
                  protocols = lib.concatStringsSep "," [ "usenet" ];
                  api_key = "filepath:${config.services."${name}".sonarr_api_key}";
                }
              ];
              radarr = [
                {
                  url = "http://localhost:${toString config.services.radarr.settings.server.port}";
                  paths = [ completeDir ];
                  protocols = lib.concatStringsSep "," [ "usenet" ];
                  api_key = "filepath:${config.services."${name}".radarr_api_key}";
                }
              ];
            };
        };
      };
    };
}
