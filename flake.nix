#
# Based on gist https://gist.github.com/phaer/e0a5cd7458cb13b70b43d50659b94c17
# provided by phaer.
#
# This flake builds the 'kexec' branch of nix-dabei with ability to do custom
# configuration.

{
  description = "An example NixOS configuration for testing the nix-dabei kexec auto-installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-dabei.url = "github:dep-sys/nix-dabei/kexec";
  };

  outputs = { self, nix-dabei, nixpkgs }: 
  let
    sshKeys = [ "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBPKBVrtVHb2Y8L2ntrjF8R6zF06WF+fP49YcJglgXLPwqSWwCE+osLz/ylDPTcufznhz72qFswB25r74HSGUSLwAAAAEc3NoOg== HTZ__nix-dabei__dante" ];
    bootDisk = "/dev/sda";
  in {
    # Build 'nix-dabei'
    kexec = (nix-dabei.lib.makeInstaller [
        ({ config, modulesPath, ... }: {
          imports = [
            "${modulesPath}/profiles/qemu-guest.nix"
          ];
          config = {
            nix-dabei = {
              zfs.enable = true;
              diskDevice = bootDisk;
            };
            users.users.root.openssh.authorizedKeys.keys = sshKeys;
          };
        })
      ] ).config.system.build.kexec;


    # System(s) to configure/ deploy.
    nixosConfigurations = {
      nix-dabei-demo = ( nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ({ ... }: {
          networking.hostName = "nix-dabei-demo";
          networking.hostId = builtins.substring 0 8 (builtins.hashString "sha256" "nix-dabei-demo");
          system.stateVersion = "22.11";

          boot = { 
            initrd = {
              availableKernelModules = [ "virtio-pci" "virtio_scsi" "ata_piix" "sd_mod" "sr_mod" "ahci" "nvme" ];
              network.ssh.enable = true;
              network.ssh.authorizedKeys = sshKeys;
            };  
            loader.grub = {
              enable = true;
              devices = [ bootDisk ];
            };
            supportedFilesystems = [ "zfs" ];
            zfs.devNodes = "/dev/disk/by-path";
          };
          fileSystems = {
            "/" = {
              device = "rpool/local/root";
              fsType = "zfs";
            };
            "/boot" = {
              device = "/dev/disk/by-partlabel/ESP";
              fsType = "auto";
            };
            "/nix" = {
              device = "rpool/local/nix";
              fsType = "zfs";
            };
            "/home" = {
              device = "rpool/safe/home";
              fsType = "zfs";
            };
          };

          services.sshd.enable = true;
          users.users.root.openssh.authorizedKeys.keys = sshKeys;
        } ) ];
      } ).config.system.build.toplevel;
    };
  };
}
