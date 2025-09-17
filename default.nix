{
  config,
  lib,
  pkgs,
  crane,
  lastsignal-src ? null,
  ...
}:
with lib; let
  cfg = config.services.lastsignal;

  lastsignal = if (lastsignal-src != null) then
    crane.buildPackage {
      src = lastsignal-src;
      buildInputs = with pkgs; [
        openssl
      ] ++ lib.optionals stdenv.isDarwin [
        darwin.apple_sdk.frameworks.Security
        darwin.apple_sdk.frameworks.SystemConfiguration
      ];
      nativeBuildInputs = with pkgs; [
        pkg-config
      ];
    }
  else
    throw "lastsignal-src is required";
in {
  options.services.lastsignal = {
    enable = mkEnableOption "LastSignal safety check-in system";

    user = mkOption {
      type = types.str;
      default = "lastsignal";
      description = "User account under which LastSignal runs";
    };

    group = mkOption {
      type = types.str;
      default = "lastsignal";
      description = "Group account under which LastSignal runs";
    };

    dataDirectory = mkOption {
      type = types.path;
      default = "~/.lastsignal";
      description = "Directory where LastSignal stores its state";
    };

    configFile = mkOption {
      type = types.path;
      description = "Path to the LastSignal configuration file";
      example = literalExpression ''
        pkgs.writeText "lastsignal-config.toml" '''
          [checkin]
          duration_between_checkins = "7d"
          output_retry_delay = "24h"

          [[checkin.outputs]]
          type = "email"
          config = { to = "you@example.com", smtp_host = "smtp.gmail.com", smtp_port = "587", username = "you@gmail.com", password = "app-password" }

          [recipient]
          max_time_since_last_checkin = "14d"

          [[recipient.last_signal_outputs]]
          type = "email"
          config = { to = "emergency@example.com", smtp_host = "smtp.gmail.com", smtp_port = "587", username = "you@gmail.com", password = "app-password" }

          [last_signal]
          adapter_type = "file"
          message_file = "~/.lastsignal/message.txt"

          [app]
          data_directory = "~/.lastsignal"
          log_level = "info"
        '''
      '';
    };


    installBinary = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install the lastsignal binary in the system environment for command-line use.";
    };
  };

  config = mkIf cfg.enable {
    # Install the binary system-wide if requested
    environment.systemPackages = mkIf cfg.installBinary [ lastsignal ];
    systemd.services.lastsignal = {
      description = "LastSignal Safety Check-in System";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${lastsignal}/bin/lastsignal run --config ${cfg.configFile}";
        Restart = "always";
        RestartSec = "30";
        WorkingDirectory = cfg.dataDirectory;

        # Security hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ReadWritePaths = [cfg.dataDirectory];
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
      };

      preStart = ''
        # Ensure data directory exists with correct permissions
        mkdir -p ${cfg.dataDirectory}
        chown ${cfg.user}:${cfg.group} ${cfg.dataDirectory}
        chmod 755 ${cfg.dataDirectory}
      '';

      environment = {
        RUST_LOG = "info";
      };
    };

    # Optional: Create a timer for periodic health checks
    systemd.timers.lastsignal-test = {
      description = "Test LastSignal outputs periodically";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      wantedBy = ["timers.target"];
    };

    systemd.services.lastsignal-test = {
      description = "Test LastSignal outputs";
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${lastsignal}/bin/lastsignal test --config ${cfg.configFile}";
        WorkingDirectory = cfg.dataDirectory;
      };
    };
  };
}

