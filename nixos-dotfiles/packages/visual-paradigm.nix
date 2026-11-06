{ pkgs }:

let
  version = "18.1";
  build = "20261101";
  archiveName = "Visual_Paradigm_CE_18_1_${build}_Linux64_InstallFree.tar.gz";

  archive = pkgs.requireFile {
    name = archiveName;
    hash = "sha256-FhF1CKtXyyhOE9cuAhM3pHrXjukpGfNJTZznJaPHcI8=";
    message = ''
      Visual Paradigm ${version} build ${build} must be added manually to the Nix store.

      Download the Linux 64-bit InstallFree archive from:
        https://www.visual-paradigm.com/download/community.jsp?platform=linux

      Then run:
        nix-store --add-fixed sha256 /path/to/${archiveName}
    '';
  };

  payload = pkgs.stdenvNoCC.mkDerivation {
    pname = "visual-paradigm";
    inherit version;
    src = archive;
    sourceRoot = "Visual_Paradigm_CE_18.1";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib
      cp -r . $out/lib/visual-paradigm
      chmod +x $out/lib/visual-paradigm/Application/scripts/VisualParadigm.sh

      runHook postInstall
    '';
  };
in
pkgs.buildFHSEnv {
  name = "visual-paradigm";
  targetPkgs = pkgs': with pkgs'; [
    alsa-lib
    fontconfig
    freetype
    libGL
    libX11
    libXext
    libXi
    libXrender
    libXtst
    libxkbcommon
    nss
    zlib
  ];
  runScript = pkgs.writeShellScript "visual-paradigm-launch" ''
    cd ${payload}/lib/visual-paradigm/Application/scripts
    exec ./VisualParadigm.sh "$@"
  '';
  extraInstallCommands = ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/visual-paradigm.desktop <<'EOF'
    [Desktop Entry]
    Type=Application
    Name=Visual Paradigm
    Exec=visual-paradigm
    Categories=Development;Graphics;
    EOF
  '';

  meta = {
    description = "Visual Paradigm Community Edition";
    homepage = "https://www.visual-paradigm.com/editions/community/";
    license = pkgs.lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
