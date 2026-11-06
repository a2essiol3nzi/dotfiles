{ pkgs }:

let
  version = "0.167.0";
  packageName = "codex-package-x86_64-unknown-linux-musl";
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/${packageName}.tar.gz";
    hash = "sha256-O7916D3mtYrtKPLPbjOtQj7DH9RwChRXuUvlV+pafG4=";
  };

  sourceRoot = ".";

  # Preserve the upstream layout and bytes: resource manifests include hashes.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -a bin codex-package.json codex-path codex-resources "$out/"

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ pkgs.python3 ];
  installCheckPhase = ''
    runHook preInstallCheck

    # Keep Codex's startup state writable and separate from its temporary files.
    export HOME="$(mktemp -d)"
    export CODEX_HOME="$HOME/.codex"
    export TMPDIR="$HOME/tmp"
    mkdir -p "$CODEX_HOME" "$TMPDIR"

    # Check the complete package layout, payload integrity and CLI version.
    python3 - "$out" <<'PY'
    import hashlib
    import json
    import os
    from pathlib import Path
    import subprocess
    import sys

    root = Path(sys.argv[1])
    manifest = json.loads((root / "codex-package.json").read_text())
    assert manifest["layoutVersion"] == 1
    assert manifest["version"] == "${version}"
    assert manifest["target"] == "x86_64-unknown-linux-musl"
    assert manifest["variant"] == "codex"
    for key in ("entrypoint", "execServer"):
        executable = root / manifest[key]
        assert executable.is_file() and os.access(executable, os.X_OK), executable
    for key in ("resourcesDir", "pathDir"):
        assert (root / manifest[key]).is_dir(), key
    for relative in (
        "bin/codex-code-mode-host",
        "codex-path/rg",
        "codex-resources/bwrap",
    ):
        executable = root / relative
        assert executable.is_file() and os.access(executable, os.X_OK), executable
    voice = json.loads((root / "codex-resources/voice/manifest.json").read_text())
    for relative, expected in voice["sha256"].items():
        with (root / relative).open("rb") as stream:
            actual = hashlib.file_digest(stream, "sha256").hexdigest()
        assert actual == expected, f"Modified upstream payload: {relative}"
    version = subprocess.check_output(
        [str(root / manifest["entrypoint"]), "--version"], text=True
    ).strip()
    assert version == "codex-cli ${version}", version
    print("PASS: Codex package layout, payload hashes and CLI version")
    PY

    runHook postInstallCheck
  '';

  meta = {
    description = "OpenAI Codex CLI";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${version}";
    license = pkgs.lib.licenses.asl20;
    mainProgram = "codex";
    platforms = [ "x86_64-linux" ];
  };
}
