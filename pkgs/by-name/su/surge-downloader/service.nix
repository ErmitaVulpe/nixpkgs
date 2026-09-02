# Non-module dependencies (`importApply`)
{ }:

# Service module
{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.surge-downloader;
in
{
  _class = "service";

  meta.maintainers = with lib.maintainers; [ ErmitaVulpe ];

  options.surge-downloader = {
    package = lib.mkOption {
      description = "Package to use for surge-downloader";
      defaultText = "The package that provided this module.";
      type = lib.types.package;
    };

    token = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Api token for the server. If null, will use an auto-generated. To see what it is, run `surge token`";
    };

    extraArgs = lib.mkOption {
      description = "Extra arguments to pass to `surge server`";
      type = with lib.types; listOf str;
      default = [ ];
    };
  };

  config = {
    process = {
      argv = [
        (lib.getExe cfg.package)
        "server"
        "start"
        "--is-system-service"
      ]
      ++ lib.optionals (cfg.token != null) [
        "--token"
        cfg.token
      ]
      ++ cfg.extraArgs;
    };

    configData."surge-downloader/themes/dummytheme" = {
      text = "";
    };
  }
  // lib.optionalAttrs (options ? systemd) (
    let
      configDirPath = dirOf (dirOf (dirOf config.configData."surge-downloader/themes/dummytheme".path));
      serviceCapabilities = [
        "CAP_DAC_OVERRIDE" # Needed to write downloaded files to user specified dirs
      ];
    in
    {
      systemd.mainExecStart = config.systemd.lib.escapeSystemdExecArgs config.process.argv;

      systemd.service = {
        description = "Surge downloader headless server";

        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        environment = {
          XDG_CONFIG_HOME = configDirPath;
          XDG_STATE_HOME = "%S";
        };

        serviceConfig = {
          Restart = "on-failure";

          ProtectSystem = "full";

          StateDirectory = "surge-downloader";

          # Hardening
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          CapabilityBoundingSet = serviceCapabilities;
          AmbientCapabilities = serviceCapabilities;
          SystemCallFilter = "@system-service";
          ProtectProc = "noaccess";
        };
      };
    }
  );
}

# DeviceAllow = "/dev/net/tun";
# ProtectHome = true;
# ProtectKernelLogs = true;
# ProtectKernelModules = true;
# ProtectProc = "invisible";
# RestrictRealtime = true;
