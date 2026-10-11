{
  flake.modules.nixos.cloudflare =
    { config, lib, ... }:
    {
      options.homelab.cloudflare.domainCertificates = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = { };
        example = ''
          {
            "foo.com" = "/path/to/foo.pem";
            "bar.com" = "/path/to/bar.pem";
          }
        '';
      };
      options.homelab.cloudflare.tunnelCredentials = lib.mkOption {
        type = lib.types.path;
      };
      config =
        let
          alphanumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
          removeAlnum =
            s:
            builtins.concatStringsSep "" (
              builtins.filter (
                c: builtins.match ".*" c != null && builtins.elem c (lib.stringToCharacters alphanumeric)
              ) (lib.stringToCharacters s)
            );
          mkTunnelName = domain: "${config.networking.hostName}-${removeAlnum domain}";

          stripHttps = url: lib.removePrefix "https://" (lib.removePrefix "http://" url);

          publicServices = lib.mapAttrs' (
            name: cfg:
            # lib.nameValuePair (stripHttps cfg.publicUrl) "http://localhost:${toString cfg.traefik.service.port}"
            lib.nameValuePair (stripHttps cfg.publicUrl) "http://localhost:4443"
          ) (lib.filterAttrs (_: v: builtins.isString v.publicUrl) config.homelab.services);

          hostname = config.networking.hostName;
        in
        {
          services.cloudflared = {
            enable = true;
            tunnels."${hostname}" = {
              credentialsFile = config.homelab.cloudflare.tunnelCredentials;
              default = "http_status:404";
              ingress = builtins.trace (builtins.deepSeq publicServices publicServices) publicServices;
            };
            # tunnels = lib.mapAttrs' (
            #   domain: cert:
            #   lib.nameValuePair (mkTunnelName domain) {
            #     certificateFile = cert;
            #     credentialsFile = "/tmp/${mkTunnelName domain}";
            #     default = "http_status:404";
            #     originRequest = {
            #       originServerName = domain;
            #     };
            #     # ingress = builtins.trace (publicServices) {
            #     #
            #     # };
            #   }
            # ) config.homelab.cloudflare.domainCertificates;
          };
        };
    };
}
