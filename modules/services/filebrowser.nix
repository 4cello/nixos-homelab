{ ... }:
let
  name = "filebrowser";
in
{
  flake.modules.nixos."${name}" =
    {
      config,
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      hl = config.homelab;
      cfg = config.services.filebrowser-quantum;
      configFormat = pkgs.formats.yaml { };
    in
    {
      options.services.filebrowser-quantum = {
        enable = lib.mkEnableOption "FileBrowser Quantum";
        package = lib.mkPackageOption pkgs "filebrowser-quantum" { };
        dataDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/filebrowser-quantum";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "filebrowser";
          description = "User account under which FileBrowser runs.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "filebrowser";
          description = "Group under which FileBrowser runs.";
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/run/secrets/filebrowser";
          description = ''
            Path to a file containing extra paperless config options in the systemd `EnvironmentFile`
            format. Refer to the [documentation](https://filebrowserquantum.com/en/docs/reference/environment-variables/) for
            config options.
          '';
        };

        settings = lib.mkOption {
          default = { };
          description = ''
            Settings for FileBrowser.
            Refer to <https://filebrowser.org/cli/filebrowser#options> for all supported values.
          '';
          type = lib.types.submodule {
            freeformType = configFormat.type;
          };
        };
      };

      config = {

        nixpkgs.overlays = [
          (final: prev: {
            filebrowser-quantum_2 =
              let
                version = "2.0.1-stable";
                src = pkgs.fetchFromGitHub {
                  owner = "gtsteffaniak";
                  repo = "filebrowser";
                  tag = "v${version}";
                  hash = "sha256-iJ7E9SguLIwy6aBlg9dQEsCzX0bU4MR07HbZb7EL3yU=";
                };

                frontend = pkgs.buildNpmPackage {
                  pname = "filebrowser-quantum-frontend";
                  inherit version src;

                  sourceRoot = "${src.name}/frontend";
                  npmDepsHash = "sha256-ZJZtHaeNpHV7n3cT0m7YmBuIGM8CObp3IdQWdSiqbKc=";

                  buildPhase = ''
                    runHook preBuild

                    npm run build:docker -- --outDir ./dist

                    runHook postBuild
                  '';

                  installPhase = ''
                    runHook preInstall

                    mkdir -p $out
                    cp -r dist/* $out

                    runHook postInstall
                  '';
                };
              in
              prev.filebrowser-quantum.override {
                buildGoModule =
                  previousArgs:
                  (prev.buildGoModule.override {
                    go = final.go_1_27;
                  })
                    (
                      previousArgs
                      // {
                        inherit version src;
                        vendorHash = "sha256-P3H5kESEd1X5tl0EQyIm680fKz/18KegoPBp1jb69vo=";

                        doCheck = false;
                        preBuild = ''
                          mkdir -p internal/web/embed
                          cp -r ${frontend}/* internal/web/embed/
                        '';
                      }
                    );

              };
          })
        ];

        systemd = {
          services.filebrowser-quantum = lib.mkIf cfg.enable {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            path = [ pkgs.ffmpeg ];
            serviceConfig = {
              ExecStart =
                let
                  args = [
                    (lib.getExe cfg.package)
                    "-c"
                    (configFormat.generate "config.yaml" cfg.settings)
                  ];
                in
                utils.escapeSystemdExecArgs args;
              WorkingDirectory = "/var/lib/filebrowser-quantum";
              StateDirectory = "filebrowser-quantum";
              StateDirectoryMode = "0750";
              CacheDirectory = name;
              # WorkingDirectory = cfg.settings.root;
              EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;

              User = cfg.user;
              Group = cfg.group;
              UMask = "0077";

              NoNewPrivileges = true;
              PrivateDevices = true;
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectControlGroups = true;
              MemoryDenyWriteExecute = true;
              LockPersonality = true;
              RestrictAddressFamilies = [
                "AF_UNIX"
                "AF_INET"
                "AF_INET6"
              ];
              DevicePolicy = "closed";
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
            };
          };
          tmpfiles.settings."${name}" = {
            # "${cfg.settings.root}".d = {
            #   inherit (cfg) user group;
            #   mode = "0700";
            # };
            # "${cfg.settings.cache-dir}".d = {
            #   inherit (cfg) user group;
            #   mode = "0700";
            # };
            # "${dirOf cfg.settings.database}".d = {
            #   inherit (cfg) user group;
            #   mode = "0700";
            # };
          };
        };

        networking.firewall.trustedInterfaces = [ "tailscale0" ];

        services.filebrowser-quantum = {
          enable = true;
          package = pkgs.filebrowser-quantum_2;
          user = hl.user.name;
          group = hl.group.name;
          dataDir = "${hl.mounts.config}/${name}";
          settings = {
            http = {
              port = 6741;
              trustProxyHeaders = true;
            };
            server = {
              sources = [
                {
                  path = "/srv/merged";
                  config.defaultEnabled = false;
                }
              ];
            };
            auth = {
              methods = {
                password.enabled = false;
                oidc = {
                  enabled = true;
                  # clientId= <client-id>
                  # clientSecret= <client-secret>
                  issuerUrl = hl.oidcUrl;
                  scopes = "email openid profile groups";
                  userIdentifier = "preferred_username";
                  disableVerifyTLS = false;
                  # Below is optional. Also add 'groups' to 'scopes' if using this
                  adminGroup = "admins";
                };
              };
            };
          };
        };

        homelab.services."${name}" = {
          traefik.service.port = config.services.filebrowser-quantum.settings.http.port;
        };
      };
    };
}
