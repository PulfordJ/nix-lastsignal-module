# LastSignal NixOS Module

A NixOS module for the LastSignal automated safety check-in system.

## Usage

Add this module to your NixOS configuration:

```nix
# In your configuration.nix or flake
imports = [ ./path/to/nix-lastsignal-module ];

services.lastsignal = {
  enable = true;
  configFile = ./lastsignal-config.toml; # or any other path
};
```

## Configuration File

You must provide a configuration file. This can be:

### Plain Configuration File

```nix
services.lastsignal = {
  enable = true;
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
    message_file = "~/.lastsignal/message.txt"
    
    [app]
    data_directory = "~/.lastsignal"
    log_level = "info"
  '';
};
```

### Encrypted Configuration with agenix

```nix
services.lastsignal = {
  enable = true;
  configFile = config.age.secrets.lastsignal-config.path;
};

# In your secrets configuration
age.secrets.lastsignal-config = {
  file = ./secrets/lastsignal-config.toml.age;
  owner = "lastsignal";
  group = "lastsignal";
  mode = "0400";
};
```

### Encrypted Configuration with sops-nix

```nix
services.lastsignal = {
  enable = true;
  configFile = config.sops.secrets.lastsignal-config.path;
};

# In your secrets configuration
sops.secrets.lastsignal-config = {
  sopsFile = ./secrets.yaml;
  owner = "lastsignal";
  group = "lastsignal";
  mode = "0400";
};
```

## Configuration Options

- `enable`: Whether to enable the LastSignal service
- `user`: User account for the service (default: "lastsignal")
- `group`: Group account for the service (default: "lastsignal") 
- `dataDirectory`: Directory for state files (default: "/var/lib/lastsignal")
- `configFile`: Path to the LastSignal configuration file (required)
- `sha256`: SHA256 hash of the LastSignal source (default: empty string for auto-calculation)
- `cargoSha256`: SHA256 hash of the Cargo dependencies (default: empty string for auto-calculation)

## Security

The module includes security hardening:
- Runs as dedicated non-root user
- Restricted filesystem access
- Protected kernel interfaces
- Configuration files with restricted permissions

## Manual Commands

After enabling the service, you can use these commands:

```bash
# Manual check-in (you'll need to specify the path to your config file)
sudo -u lastsignal lastsignal --config /path/to/your/config.toml checkin

# Check status  
sudo -u lastsignal lastsignal --config /path/to/your/config.toml status

# Test outputs
sudo -u lastsignal lastsignal --config /path/to/your/config.toml test

# For encrypted configs with agenix/sops, use the decrypted path:
# sudo -u lastsignal lastsignal --config /run/secrets/lastsignal-config checkin
```

## Hash Configuration

The module supports configurable source and cargo hashes:

### Automatic Hash Calculation (Default)

By default, both `sha256` and `cargoSha256` are empty strings, which will cause Nix to calculate the correct hashes automatically. On first build, Nix will fail with error messages containing the correct hashes.

### Manual Hash Specification

You can specify the hashes directly in your configuration:

```nix
services.lastsignal = {
  enable = true;
  configFile = ./lastsignal-config.toml;
  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  cargoSha256 = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
};
```

### Getting the Correct Hashes

1. Run `nixos-rebuild switch` (or `nix-build` if testing)
2. Nix will fail and provide the correct hashes in error messages
3. Copy these hashes to your configuration if you want to pin them