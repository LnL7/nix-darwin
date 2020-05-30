{
  # WARNING this is very much still experimental.
  description = "A collection of darwin modules";

  outputs = { self }: {

    darwinModules = import ./modules/module-list.nix;

    examples.lnl = import ./modules/examples/lnl.nix;
    examples.simple = import ./modules/examples/simple.nix;

  };
}
