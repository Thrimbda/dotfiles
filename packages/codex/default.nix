{ lib, stdenv, fetchurl, autoPatchelfHook, ncurses, ... }:

stdenv.mkDerivation rec {
  pname = "codex";
  version = "0.154.0";

  # Use the complete official standalone bundle, including code-mode and sandbox
  # helpers. The bundled zsh still needs its ELF loader/libraries fixed on NixOS.
  src = fetchurl {
    url = "https://releases.openai.com/codex/releases/${version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-/G4+O4Xyz31mRSDuXGan/kqhK659RoNPR+LxZf0Nb3g=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ ncurses stdenv.cc.cc.lib ];
  sourceRoot = ".";
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r bin codex-package.json codex-path codex-resources "$out/"
    ln -s bin/codex "$out/codex"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/codex" --version | grep -Fx 'codex-cli ${version}'
    "$out/bin/codex-code-mode-host" --help >/dev/null
    "$out/codex-path/rg" --version >/dev/null
    "$out/codex-resources/bwrap" --version >/dev/null
    "$out/codex-resources/zsh/bin/zsh" -fc '(( 2 + 2 == 4 ))'
    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Codex CLI and App Server, official standalone bundle";
    homepage = "https://github.com/openai/codex";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
