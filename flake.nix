{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    zellij = {
      url = "github:zellij-org/zellij";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    utils,
    zellij,
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      devShell = with pkgs;
        mkShell {
          buildInputs = [cargo rustc rustfmt pre-commit rustPackages.clippy];
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
        };
      defaultPackage = let
        manifest = (pkgs.lib.importTOML ./Cargo.toml).package;
      in
        pkgs.rustPlatform.buildRustPackage (finalAttrs: {
          # Remove the `vendored_curl` feature in order to link against the
          # libcurl from nixpkgs instead of the vendored one
          postPatch = ''
            substituteInPlace Cargo.toml \
              --replace-fail ', "vendored_curl"' ""
          '';
          cargoVendorDir = finalAttrs.src;
          name = manifest.name;
          version = manifest.version;
          cargoLock.lockFile = ./Cargo.lock;
          # TODO
          # src = zellij;

          env.OPENSSL_NO_VENDOR = 1;

          nativeBuildInputs = with pkgs; [
            mandown
            installShellFiles
            pkg-config
            (lib.getDev curl)
          ];

          buildInputs = with pkgs; [
            curl
            openssl
          ];

          nativeCheckInputs = with pkgs; [
            writableTmpDirAsHomeHook
          ];

          nativeInstallCheckInputs = with pkgs; [
            versionCheckHook
          ];
          versionCheckProgramArg = "--version";
          doInstallCheck = true;

          # Ensure that we don't vendor curl, but instead link against the libcurl from nixpkgs
          installCheckPhase = pkgs.lib.optionalString (pkgs.stdenv.hostPlatform.libc == "glibc") ''
            runHook preInstallCheck

            ldd "$out/bin/zellij" | grep libcurl.so

            runHook postInstallCheck
          '';

          postInstall =
            ''
              mandown docs/MANPAGE.md > zellij.1
              installManPage zellij.1
            ''
            + pkgs.lib.optionalString (pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform) ''
              installShellCompletion --cmd $pname \
                --bash <($out/bin/zellij setup --generate-completion bash) \
                --fish <($out/bin/zellij setup --generate-completion fish) \
                --zsh <($out/bin/zellij setup --generate-completion zsh)
            '';

          # passthru.updateScript = nix-update-script { };
        });
    });
}
