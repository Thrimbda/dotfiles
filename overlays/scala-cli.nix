final: prev: {
  scala-cli = prev.scala-cli.overrideAttrs (old: rec {
    version = "0.1.10";
    src = prev.fetchurl {
      url = "https://github.com/Virtuslab/scala-cli/releases/download/v0.1.10/scala-cli-x86_64-pc-linux.gz";
      sha256 = "YDgRDtsXj6HZdpJLrnXqBTf92HLOEsIEcPKGCevMWHI=";
    };
  });
}