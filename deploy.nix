{inputs ? import ./flake-compat/inputs.nix, ...}: {
  nodes.fermi = {
    hostname = "170.130.165.174";
    profiles.system = {
      user = "root";
      path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.fermi;
    };
  };
}
