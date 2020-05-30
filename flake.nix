{
  # WARNING this is very much still experimental.
  description = "A collection of darwin modules";

  outputs = { self, nixpkgs }: {

    lib = {
      evalConfig = import ./eval-config.nix { inherit (nixpkgs) lib; };
    };

    examples.lnl = import ./modules/examples/lnl.nix;
    examples.simple = import ./modules/examples/simple.nix;

    checks.x86_64-darwin.simple = (self.lib.evalConfig {
      configuration = self.examples.simple;
      inputs.nixpkgs = nixpkgs;
    }).system;

  };
}
