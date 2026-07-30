{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, ...
}:

stdenv.mkDerivation rec {
  pname = "auth-mini";
  version = "latest-2026-07-24";

  src = fetchurl {
    url = "https://api.github.com/repos/zccz14/auth-mini/releases/assets/488807338";
    curlOpts = "--header Accept:application/octet-stream";
    hash = "sha256-aAIhKH4MyncxGs9rXJdDCJ2I2RFTMrqDqfPONd6QiSI=";
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
