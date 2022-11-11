{
  description = "An example NixOS configuration for testing the nix-dabei kexec auto-installer";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self,  nixpkgs }: {
    nixosConfigurations = {

      mysystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        
        modules = [ ({ ... }: {
          networking.hostName = "mysystem";

          boot.loader.systemd-boot.enable = true;

          services.sshd.enable = true;
          users.users.root.openssh.authorizedKeys.keys = [ "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBPKBVrtVHb2Y8L2ntrjF8R6zF06WF+fP49YcJglgXLPwqSWwCE+osLz/ylDPTcufznhz72qFswB25r74HSGUSLwAAAAEc3NoOg== HTZ__nix-dabei__dante" ];
        }) ];
      };
    };
  };
}
