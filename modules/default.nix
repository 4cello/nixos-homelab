{
  flake.modules.nixos.homelab =
    { lib, config, ... }:
    let
      cfg = config.homelab;
    in
    {
      options.homelab = {
        enable = lib.mkEnableOption "The homelab services and configuration variables";
        mounts.slow = lib.mkOption {
          default = "/mnt/mergerfs_slow";
          type = lib.types.path;
          description = ''
            Path to the 'slow' tier mount
          '';
        };
        mounts.fast = lib.mkOption {
          default = "/mnt/cache";
          type = lib.types.path;
          description = ''
            Path to the 'fast' tier mount
          '';
        };
        mounts.config = lib.mkOption {
          default = "/persist/opt/services";
          type = lib.types.path;
          description = ''
            Path to the service configuration files
          '';
        };
        mounts.merged = lib.mkOption {
          default = "/mnt/merged";
          type = lib.types.path;
          description = ''
            Path to the merged tier mount
          '';
        };
        user.name = lib.mkOption {
          default = "share";
          type = lib.types.str;
          description = ''
            User to run the homelab services as
          '';
        };
        user.id = lib.mkOption {
          default = 807;
          type = lib.types.int;
          description = ''
            User id to run the homelab services as
          '';
        };
        group.name = lib.mkOption {
          default = "share";
          type = lib.types.str;
          description = ''
            Group to run the homelab services as
          '';
        };
        group.id = lib.mkOption {
          default = 806;
          type = lib.types.int;
          description = ''
            Group id to run the homelab services as
          '';
        };
        timeZone = lib.mkOption {
          default = "Europe/Berlin";
          type = lib.types.str;
          description = ''
            Time zone to be used for the homelab services
          '';
        };
        baseDomain = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = ''
            Base domain name to be used to access the homelab services via reverse proxy
          '';
        };
        oidcUrl = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = ''
            OIDC Issuer URL for the homelab services
          '';
        };
        cloudflare.dnsCredentialsFile = lib.mkOption {
          type = lib.types.path;
          example = ''
            CF_DNS_API_TOKEN=verybigsecret
            CF_API_EMAIL=foo@bar.com
          '';
        };
      };
      config = lib.mkIf cfg.enable {
        users = {
          groups.${cfg.group.name} = {
            gid = cfg.group.id;
          };
          users.${cfg.user.name} = {
            uid = cfg.user.id;
            isSystemUser = true;
            group = cfg.group.name;
          };
        };
      };
    };
}
