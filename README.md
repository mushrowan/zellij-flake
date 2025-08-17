# Zellij flake

[Zellij](https://github.com/zellij-org/zellij/), as a Nix flake!

This is mostly a miniproject to give me a bit more experience with packaging and
flakes. However, it does work. Feel free to use it if you want.

I still need to set up a watcher to keep the lockfile up-to-date with upstream
zellij. If you want to make sure that you have the latest upstream, you can set
up a separate zellij input in your own flake for zellij-flake to follow.

## Todos

- Set up a binary cache

## Usage

#### flake.nix:

```nix
{
  inputs = {
    zellij-flake = {
      url = "github:mushrowan/zellij-flake";
      # To reduce build/pull times, you can set your own nixpkgs input
      # inputs.nixpkgs.follows = "nixpkgs";
      # To override with your own zellij input
      # inputs.zellij.follows = "zellij";
    };
    
  };
  outputs = {self, ...} @ inputs: {
  # [...]
  };
}
```

#### configuration.nix:

```nix
{inputs, ...}: {
    # Just the package
    environment.systemPackages = [
        # Replace arch with your system's arch, or use pkgs.stdenv.hostPlatform.system
        inputs.zellij-flake.defaultPackage."x86_64-linux"
    ];
}
```

Alternatively, you can use the home-manager zellij module, and change the
module's package option:

#### home.nix

```nix
{inputs, ...}: {
    programs.zellij = {
        enable = true;
        # Replace arch with your system's arch, or use pkgs.stdenv.hostPlatform.system
        package = inputs.zellij-flake.defaultPackage."x86_64-linux";
    };
}
```

Note that the home-manager module may not be compatible with the latest version
of zellij, so stuff may break. If this happens, you could figure out what is
breaking and fix it in home-manager, and PR it in!
