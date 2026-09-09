{ lib, stdenvNoCC, fetchurl, autoPatchelfHook, bzip2, coreutils, gnutar, unzip, zip, python3, psmisc, jre, stdenv }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "connect-tunnel";
  version = "12.50.00247";

  src = fetchurl {
    url = "https://software.sonicwall.com/CT-NX-VPNClients/CT-12.5.0/ConnectTunnel_Linux64-12.50.00247.tar";
    hash = "sha256-36kS8zgtNO9PaH32SW04UhM95rlTNgjEr/957lotIOk=";
  };

  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook bzip2 gnutar unzip zip python3 ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    mkdir -p "$out/libexec" "$out/bin" "$out/share/applications"
    tar -xOf "$src" ConnectTunnel-Linux64-12.50.00247.tar.bz2 \
      | tar -xj --strip-components=3 -C "$out"

    mv "$out/AvConnect" "$out/libexec/AvConnect.bin"
    tar -xjf "$out/certs.tar.bz2" -C "$out/libexec"
    tar -xOf "$src" version > "$out/libexec/version"
    rm "$out/certs.tar.bz2" "$out/startct.sh" "$out/startctui.sh" "$out/uninstall.sh"

    # The Java client hard-codes /usr/local/Aventail.  Redirect it to the
    # active NixOS system profile, where libexec contains launcher and metadata.
    mkdir jar
    unzip -q "$out/ui/SnwlConnect.jar" -d jar
    python3 - <<'PY'
from pathlib import Path
path = Path("jar/com/sonicwall/nixconnect/util/Util.class")
data = path.read_bytes()

def replace_utf8(data, old, new):
    token = b"\x01" + len(old).to_bytes(2, "big") + old
    replacement = b"\x01" + len(new).to_bytes(2, "big") + new
    assert data.count(token) == 1
    return data.replace(token, replacement)

data = replace_utf8(data, b"/usr/local/Aventail", b"/run/current-system/sw/libexec")
data = replace_utf8(data, b"/usr/local/Aventail/version", b"/run/current-system/sw/libexec/version")

for class_file in [
    Path("jar/com/sonicwall/connect/proxy/ProxyHandler.class"),
    Path("jar/com/sonicwall/connect/util/NixScriptExecutor.class"),
]:
    class_data = class_file.read_bytes()
    assert class_data.count(b"/bin/bash") == 1
    class_file.write_bytes(class_data.replace(b"/bin/bash", b"///bin/sh"))

path.write_bytes(data)
PY
    rm "$out/ui/SnwlConnect.jar"
    (cd jar && zip -qr "$out/ui/SnwlConnect.jar" .)
    rm -r jar

    cat > "$out/libexec/AvConnect" <<'EOF'
#!${stdenv.shell}
exec /run/wrappers/bin/AvConnect "$@"
EOF
    chmod 0755 "$out/libexec/AvConnect"

    cat > "$out/bin/startct" <<EOF
#!${stdenv.shell}
exec ${coreutils}/bin/env PATH="${lib.makeBinPath [ psmisc ]}:\$PATH" ${jre}/bin/java -jar "$out/ui/SnwlConnect.jar" "\$@"
EOF
    cat > "$out/bin/startctui" <<EOF
#!${stdenv.shell}
exec ${coreutils}/bin/env PATH="${lib.makeBinPath [ psmisc ]}:\$PATH" ${jre}/bin/java -jar "$out/ui/SnwlConnect.jar" --mode gui "\$@"
EOF
    chmod 0755 "$out/bin/startct" "$out/bin/startctui"

    cat > "$out/share/applications/connect-tunnel.desktop" <<EOF
[Desktop Entry]
Name=Connect Tunnel
GenericName=SonicWall VPN Connection
Exec=$out/bin/startctui
Icon=$out/logo.png
Terminal=false
Type=Application
Categories=Network;
StartupWMClass=com-sonicwall-nixconnect-ConnectApplication
EOF
  '';

  meta = {
    description = "SonicWall Connect Tunnel VPN client";
    homepage = "https://www.sonicwall.com/products/remote-access/vpn-clients";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
})
