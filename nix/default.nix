{ lib, pkgs, nixpkgs, system, makeRustPlatform, rust-overlay }:
let
  rustPkgs = import nixpkgs {
    inherit system;
    overlays = [ (import rust-overlay) ];
  };

  # rustVersion = "1.61.0";

  wasmTarget = "wasm32-unknown-unknown";

  # rustWithWasmTarget = rustPkgs.rust-bin.stable.${rustVersion}.default.override {
  rustWithWasmTarget = rustPkgs.rust-bin.stable.latest.default.override {
    targets = [ wasmTarget ];
  };

  rustPlatformWasm = makeRustPlatform {
    cargo = rustWithWasmTarget;
    rustc = rustWithWasmTarget;
  };
  cargoToml = with builtins; fromTOML (readFile ../app/Cargo.toml);

  wasmBindgenMatch =
    cargoToml.dependencies.wasm-bindgen == "= ${pkgs.wasm-bindgen-cli.version}";

  assertWasmBindgen = assert (lib.assertMsg wasmBindgenMatch ''
    Due to instability in the Rust WASM ecosystem, the trunk build
    tool enforces that the Cargo-dependency version of `wasm-bindgen`
    MUST match the version of the CLI supplied in the environment.

    This can get out of sync when nixpkgs is updated. To resolve it,
    wasm-bindgen must be bumped in the Cargo.toml file and cargo needs
    to be run to resolve the dependencies.

    Versions of `wasm-bindgen` in Cargo.toml:

      Expected: '= ${pkgs.wasm-bindgen-cli.version}'
      Actual:   '${cargoToml.dependencies.wasm-bindgen}'
  ''); pkgs.wasm-bindgen-cli;

  common = {
    version = "0.5.0";
    src = ../.;

    cargoLock = {
      lockFile = ../Cargo.lock;
      outputHashes = {
        "lber-0.4.1" = "sha256-2rGTpg8puIAXggX9rEbXPdirfetNOHWfFc80xqzPMT4=";
        "opaque-ke-0.6.1" = "sha256-99gaDv7eIcYChmvOKQ4yXuaGVzo2Q6BcgSQOzsLF+fM=";
        "yew_form-0.1.8" = "sha256-1n9C7NiFfTjbmc9B5bDEnz7ZpYJo9ZT8/dioRXJ65hc=";
      };
    };

    nativeBuildInputs = with pkgs; [
      pkg-config
      wasm-pack
      binaryen
      assertWasmBindgen
      wasm-bindgen-cli
    ];
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };
in
  # backend = pkgs.rustPlatform.buildRustPackage (common // {
  #   pname = "backend";
  # });

  # frontend = rustPlatformWasm.buildRustPackage (common // {
  #   pname = "frontend";

  #   buildPhase = ''
  #     wasm-pack build app --target web --release
  #     gzip -9 -f app/pkg/lldap_app_bg.wasm
  #   '';
  #   installPhase = ''
  #     mkdir -p $out/lib
  #     cp target/wasm32-unknown-unknown/release/*.wasm $out/lib/
  #   '';
  # });
rustPlatformWasm.buildRustPackage (common // {
    pname = "lldap";
    doCheck = false;
    postPatch = ''
      substituteInPlace server/src/infra/tcp_server.rs \
        --replace "app/index.html"     "$out/share/lldap/index.html" \
        --replace "./app/pkg"          "$out/share/lldap/pkg" \
        --replace "./app/static"       "$out/share/lldap/static"
    '';
    preBuild = ''
      wasm-pack build app --target web --release
      gzip -9 -f app/pkg/lldap_app_bg.wasm
    '';
    checkPhase = ''
    '';
    postInstall = ''
      install -Dm444 app/index.html       $out/share/lldap/index.html
      cp -a          app/static           $out/share/lldap/static
      cp -a          app/pkg              $out/share/lldap/pkg
    '';

    # buildPhase = ''
    #   wasm-pack build app --target web --release
    #   gzip -9 -f app/pkg/lldap_app_bg.wasm
    # '';
    # installPhase = ''
    #   mkdir -p $out/lib
    #   cp target/wasm32-unknown-unknown/release/*.wasm $out/lib/
    # '';
})
