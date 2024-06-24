{
  cachix.enable = false;

  pre-commit.hooks = {
    nixpkgs-fmt.enable = true;
    statix.enable = true;
    deadnix.enable = true;
  };
}
