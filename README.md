# LastSignal NixOS Module

A NixOS module for the LastSignal automated safety check-in system.

## Usage

### For Flake-based Configurations

Add this module to your flake inputs:

```nix
# In your flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-lastsignal-module.url = "github:PulfordJ/nix-lastsignal-module";
    nix-lastsignal-module.inputs.nixpkgs.follows = "nixpkgs";
    nix-lastsignal-module.inputs.lastsignal-src.follows = "lastsignal-src";
    lastsignal-src = {
      url = "github:PulfordJ/lastsignal";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nix-lastsignal-module, lastsignal-src, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-lastsignal-module.nixosModules.default
        {
          services.lastsignal = {
            enable = true;
            user = "myusername";
            group = "users";
            dataDirectory = "/home/myusername/.lastsignal";
            configFile = "/home/myusername/.lastsignal/config.toml";
          };
        }
      ];
    };
  };
}
```

### For Traditional Configurations

If you're not using flakes, you need to provide the lastsignal source when importing:

```nix
# In your configuration.nix
let
  lastsignal-src = pkgs.fetchFromGitHub {
    owner = "PulfordJ";
    repo = "lastsignal";
    rev = "main";  # or specific commit/tag
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Replace with actual hash
  };
in {
  imports = [ 
    (import ./path/to/nix-lastsignal-module { inherit lastsignal-src; })
  ];

  services.lastsignal = {
    enable = true;
    configFile = ./lastsignal-config.toml;
  };
}
```

## Configuration File

You must provide a configuration file. This can be:

### Plain Configuration File

```nix
services.lastsignal = {
  enable = true;
  user = "myusername";
  group = "users";
  dataDirectory = "/home/myusername/.lastsignal";
  configFile = pkgs.writeText "lastsignal-config.toml" ''
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
    message_file = "/home/myusername/.lastsignal/message.txt"

    [app]
    data_directory = "/home/myusername/.lastsignal"
    log_level = "info"
  '';
};
```

### Encrypted Configuration with agenix

```nix
services.lastsignal = {
  enable = true;
  user = "myusername";
  group = "users";
  dataDirectory = "/home/myusername/.lastsignal";
  configFile = config.age.secrets.lastsignal-config.path;
};

# In your secrets configuration
age.secrets.lastsignal-config = {
  file = ./secrets/lastsignal-config.toml.age;
  owner = "myusername";
  group = "users";
  mode = "0400";
};
```

### Encrypted Configuration with sops-nix

```nix
services.lastsignal = {
  enable = true;
  user = "myusername";
  group = "users";
  dataDirectory = "/home/myusername/.lastsignal";
  configFile = config.sops.secrets.lastsignal-config.path;
};

# In your secrets configuration
sops.secrets.lastsignal-config = {
  sopsFile = ./secrets.yaml;
  owner = "myusername";
  group = "users";
  mode = "0400";
};
```

## Configuration Options

- `enable`: Whether to enable the LastSignal service
- `user`: User account for the service (default: "lastsignal")
- `group`: Group account for the service (default: "lastsignal")
- `dataDirectory`: Directory for state files (default: "~/.lastsignal")
- `configFile`: Path to the LastSignal configuration file (required)

## Security

The module includes security hardening:
- Runs as dedicated non-root user
- Restricted filesystem access
- Protected kernel interfaces
- Configuration files with restricted permissions

## Manual Commands

After enabling the service, you can use these commands:

```bash
# Manual check-in (using your configured user and config file)
sudo -u myusername lastsignal --config /home/myusername/.lastsignal/config.toml checkin

# Check status
sudo -u myusername lastsignal --config /home/myusername/.lastsignal/config.toml status

# Test outputs
sudo -u myusername lastsignal --config /home/myusername/.lastsignal/config.toml test

# For encrypted configs with agenix/sops, use the decrypted path:
# sudo -u myusername lastsignal --config /run/secrets/lastsignal-config checkin
```

## Hash Configuration

### Source Hash (for Traditional Configurations)

If you're using a traditional configuration (not flakes), you'll need to specify the source hash when fetching from GitHub:

```nix
let
  lastsignal-src = pkgs.fetchFromGitHub {
    owner = "PulfordJ";
    repo = "lastsignal";
    rev = "main";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # Replace with actual hash
  };
```
