{
  releaseName,
  srcs,
}:

{
  stdenvNoCC,
  fetchzip,
  clang,
  makeWrapper,
  makeBinaryWrapper,
  autoPatchelfHook,
  lib,
}:

stdenvNoCC.mkDerivation {
  pname = "odin";
  version = releaseName;

  src =
    let
      systemMapper = {
        "aarch64-linux" = "linux-arm64";
        "x86_64-linux" = "linux-amd64";
        "aarch64-darwin" = "macos-arm64";
        "x86_64-darwin" = "macos-amd64";
      };
      src = lib.findFirst (
        src: lib.hasInfix (systemMapper.${stdenvNoCC.targetPlatform.system} or "unknown-none") src.url
      ) (throw "unsupported platform: ${stdenvNoCC.targetPlatform.system}") srcs;
    in
    fetchzip src;

  nativeBuildInputs = [
    (if stdenvNoCC.targetPlatform.isDarwin then makeWrapper else makeBinaryWrapper)
    autoPatchelfHook
  ];

  buildInputs = [
    clang
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/odin

    cp -r ./* $out/libexec/odin
    makeWrapper $out/libexec/odin/odin $out/bin/odin \
        --inherit-argv0 \
        --prefix PATH : "${
          lib.makeBinPath [
            clang
          ]
        }"

    runHook postInstall
  '';

  meta = {
    description = "The Data-Oriented Language for Sane Software Development.";
    longDescription = ''
      Odin is a general-purpose programming language with distinct typing built for high performance, modern systems and data-oriented programming.

      Odin is the C alternative for the Joy of Programming.
    '';
    homepage = "https://odin-lang.org/";
    license = lib.licenses.zlib;
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
}
