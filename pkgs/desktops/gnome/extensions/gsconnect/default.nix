{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, substituteAll
, openssl
, gsound
, meson
, ninja
, pkg-config
, gobject-introspection
, wrapGAppsHook
, glib
, glib-networking
, gtk3
, openssh
, gnome
, evolution-data-server-gtk4
, gjs
, nixosTests
}:

stdenv.mkDerivation rec {
  pname = "gnome-shell-extension-gsconnect";
  version = "50";

  outputs = [ "out" "installedTests" ];

  src = fetchFromGitHub {
    owner = "GSConnect";
    repo = "gnome-shell-extension-gsconnect";
    rev = "v${version}";
    hash = "sha256-uUpdjBsVeS99AYDpGlXP9fMqGxWj+XfVubNoGJs76G0=";
  };

  patches = [
    # Make typelibs available in the extension
    (substituteAll {
      src = ./fix-paths.patch;
      gapplication = "${glib.bin}/bin/gapplication";
    })

    # Allow installing installed tests to a separate output
    ./installed-tests-path.patch

    # Update extension for Nautilus 43.
    (fetchpatch {
      url = "https://github.com/GSConnect/gnome-shell-extension-gsconnect/commit/9723ea9102f07c2c60fa065184cc58c2bc260abf.patch";
      sha256 = "9afy/70AwW+OYML5J5IyBBiNKWkZ+wZZryZbi4uRfs4=";
    })
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gobject-introspection # for locating typelibs
    wrapGAppsHook # for wrapping daemons
  ];

  buildInputs = [
    glib # libgobject
    glib-networking
    gtk3
    gsound
    gjs # for running daemon
    evolution-data-server-gtk4 # for libebook-contacts typelib
  ];

  mesonFlags = [
    "-Dgnome_shell_libdir=${gnome.gnome-shell}/lib"
    "-Dgsettings_schemadir=${glib.makeSchemaPath (placeholder "out") "${pname}-${version}"}"
    "-Dchrome_nmhdir=${placeholder "out"}/etc/opt/chrome/native-messaging-hosts"
    "-Dchromium_nmhdir=${placeholder "out"}/etc/chromium/native-messaging-hosts"
    "-Dopenssl_path=${openssl}/bin/openssl"
    "-Dsshadd_path=${openssh}/bin/ssh-add"
    "-Dsshkeygen_path=${openssh}/bin/ssh-keygen"
    "-Dsession_bus_services_dir=${placeholder "out"}/share/dbus-1/services"
    "-Dpost_install=true"
    "-Dinstalled_test_prefix=${placeholder "installedTests"}"
  ];

  postPatch = ''
    patchShebangs meson/nmh.sh
    patchShebangs meson/post-install.sh
    patchShebangs installed-tests/prepare-tests.sh

    # TODO: do not include every typelib everywhere
    # for example, we definitely do not need nautilus
    for file in src/extension.js src/prefs.js; do
      substituteInPlace "$file" \
        --subst-var-by typelibPath "$GI_TYPELIB_PATH"
    done
  '';

  postFixup = ''
    # Let’s wrap the daemons
    for file in $out/share/gnome-shell/extensions/gsconnect@andyholmes.github.io/service/{daemon,nativeMessagingHost}.js; do
      echo "Wrapping program $file"
      wrapGApp "$file"
    done

    # Wrap jasmine runner for tests
    for file in $installedTests/libexec/installed-tests/gsconnect/minijasmine; do
      echo "Wrapping program $file"
      wrapGApp "$file"
    done
  '';

  passthru = {
    extensionUuid = "gsconnect@andyholmes.github.io";
    extensionPortalSlug = "gsconnect";
  };

  passthru = {
    tests = {
      installedTests = nixosTests.installed-tests.gsconnect;
    };
  };

  meta = with lib; {
    description = "KDE Connect implementation for Gnome Shell";
    homepage = "https://github.com/GSConnect/gnome-shell-extension-gsconnect/wiki";
    license = licenses.gpl2Plus;
    maintainers = teams.gnome.members;
    platforms = platforms.linux;
  };
}
