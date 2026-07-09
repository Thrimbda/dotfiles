{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, ...
}:

stdenv.mkDerivation rec {
  pname = "auth-mini";
  version = "latest-2026-07-05";

  src = fetchurl {
    url = "https://github.com/zccz14/auth-mini/releases/download/latest/auth-mini-linux-x86_64.tar.gz";
    hash = "sha256-CT0JbhCLCjTUVdStN7r3leDapkHImSPL4o7FxdyieH4=";
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
