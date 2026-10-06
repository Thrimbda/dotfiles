{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, ...
}:

stdenv.mkDerivation rec {
  pname = "auth-mini";
  version = "latest-2026-08-23";

  src = fetchurl {
    url = "https://api.github.com/repos/zccz14/auth-mini/releases/assets/525860183";
    curlOpts = "--header Accept:application/octet-stream";
    hash = "sha256-Equym5er1VeXYN/NN2EjXVvutT3oBkAxJKedtHBWKzY=";
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
