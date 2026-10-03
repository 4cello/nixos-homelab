{
  flake.modules.nixos.traefik =
    { config, lib, ... }:
    let
      service = "traefik-${config.networking.hostName}";
      cfg = config.homelab.services."${service}";
    in
    {
      config = {
        services.traefik =
          let
            mkRule =
              name: urls:
              lib.concatStringsSep " || " (
                map (url: "Host(`${url}`)") (if builtins.isString urls then [ urls ] else urls)
              );
            mkTraefik =
              name: cfg:
              lib.mkIf cfg.traefik.enable {
                http = {
                  routers.${name} = {
                    rule = mkRule name cfg.url;
                    entryPoints = [ "websecure" ];
                    service = if builtins.isString cfg.traefik.service then cfg.traefik.service else name;
                    middlewares = cfg.traefik.middlewares;
                  };
                }
                // (lib.optionalAttrs (!builtins.isString cfg.traefik.service) {
                  services.${name} = {
                    loadBalancer.servers = [
                      {
                        url = "http://127.0.0.1:${toString cfg.traefik.service.port}";
                      }
                    ];
                  };
                });
              };

            middlewares = [
              {
                http.middlewares.tinyauth.forwardAuth = {
                  address = "https://tinyauth.${config.homelab.baseDomain}/api/auth/traefik";
                  authResponseHeaders = [
                    "remote-user"
                    "remote-name"
                    "remote-email"
                    "remote-groups"
                  ];
                };
              }
            ];
            dynamicConfigOptions = lib.mkMerge (
              middlewares ++ (lib.mapAttrsToList mkTraefik config.homelab.services)
            );
          in
          {
            inherit dynamicConfigOptions;
            enable = true;
            group = config.homelab.group.name;
            staticConfigOptions = {
              log.level = "DEBUG";
              api = {
                dashboard = true;
                insecure = true;
              };
              entryPoints = {
                web = {
                  address = ":80";
                  http = {
                    aliasHeadersStrategy = "delete";
                    redirections.entryPoint = {
                      to = "websecure";
                      scheme = "https";
                    };
                  };
                  transport.respondingTimeouts.readTimeout = "0s";
                };
                websecure = {
                  address = ":443";
                  asDefault = true;
                  http = {
                    aliasHeadersStrategy = "delete";
                    tls.certresolver = "letsencrypt";
                  };
                };
              };
              certificatesResolvers.letsencrypt.acme = {
                # storage = "";
                dnsChallenge = {
                  provider = "cloudflare";
                  resolvers = [
                    "1.1.1.1:53"
                    "8.8.8.8:53"
                  ];
                  propagation.delayBeforeChecks = 10;
                };
              };
            };
          };

        homelab.services."traefik-${config.networking.hostName}" = {
          traefik = {
            # enable = true;
            service = "api@internal";
          };
        };
      };
    };
}
