{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, ...
}:

stdenv.mkDerivation rec {
  pname = "auth-mini";
  version = "latest-2026-10-05-156484e";

  # zccz14/auth-mini publishes Rust binaries under the moving `latest` release
  # and replaces the asset on every push to main, so an asset id stops
  # resolving once upstream republishes. This asset was built by the release
  # workflow from zccz14/auth-mini@156484e69d00487151a283edf96930fac9bc9cae
  # (2026-10-05); its sha256 matches the published .sha256 asset.
  src = fetchurl {
    url = "https://api.github.com/repos/zccz14/auth-mini/releases/assets/612783099";
    curlOpts = "--header Accept:application/octet-stream";
    hash = "sha256-EP3k3hXaMVxvvsx7najo+2/89UNobhygtHLutqssocw=";
  };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -xzf "$src" -C source
    sourceRoot=source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 auth-mini "$out/bin/auth-mini"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Minimal self-hosted authentication server";
    homepage = "https://github.com/zccz14/auth-mini";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "auth-mini";
  };
}
