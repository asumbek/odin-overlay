{
  releaseName,
  srcs,
}:

{
  stdenvNoCC,
  fetchzip,
  autoPatchelfHook,
  lib,
}:

stdenvNoCC.mkDerivation {
  pname = "ols";
  version = releaseName;

  src =
    let
      systemMapper = {
        "aarch64-linux" = "arm64-unknown-linux-gnu";
        "x86_64-linux" = "x86_64-unknown-linux-gnu";
        "aarch64-darwin" = "arm64-darwin";
        "x86_64-darwin" = "x86_64-darwin";
      };
      src = lib.findFirst (
        src: lib.hasInfix (systemMapper.${stdenvNoCC.targetPlatform.system} or "unknown-none") src.url
      ) (throw "unsupported platform: ${stdenvNoCC.targetPlatform.system}") srcs;
    in
    fetchzip {
      inherit (src) url hash;
      stripRoot = false;
    };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    cp ./ols* $out/bin/ols
    cp ./odinfmt* $out/bin/odinfmt

    runHook postInstall
  '';

  meta = {
    description = "Language server for Odin.";
    homepage = "https://github.com/DanielGavin/ols/";
    license = lib.licenses.mit;
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
}
