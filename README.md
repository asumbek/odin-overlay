# odin-overlay

An overlay that provides packages for Odin compiler and also tools to work with Odin.

Only provides packages for Linux/MacOS x86_64/aarch64 platform, tested on Linux x86_64.
Regularly updated every 4 hours.

Try now!
```sh
$ nix shell github:asumbek/odin-overlay#{odin,ols}.latest

# Now you have Odin compiler and OLS/odinfmt in your env!
$ odin version
$ odinfmt -h
```
Or use it in your Nix shell...
```nix
let
  odinOverlay = builtins.fetchTarball "https://github.com/asumbek/odin-overlay/archive/main.tar.gz";
  pkgs = import <nixpkgs> { overlays = [ odinOverlay ]; };
in
pkgs.mkShell [
  buildInputs = with pkgs.odinToolchains; [
    odin.latest
    ols.latest
  ]
]
```
```sh
# Odin compiler and OLS/odinfmt now available in your shell!
$ nix-shell
```

Currently, only dev-* releases are packaged in this overlay (see [`manifests/`](./manifests)), so nightly builds are not available yet.

`odin.*` by defaults have `clang` available on-demand, you can modify which package to use for having clang on demand by overriding `odin.*`.
```nix
# Override latest Odin compiler to use clang 20 instead of the default
pkgs.odinToolchains.odin.latest.override {
  clang = pkgs.clang_20;
}
```
