{ lib
, stdenv
, javaPackages
, fetchFromGitHub
, fetchurl
, fetchpatch
, makeWrapper
, eclipse-sdk
, maven3
, openjdk8_headless
, atk
, cairo
, freetype
, gcc
, glib
, glibc
, gtk2
, jre8
, libXtst
, python
, swt
, webkitgtk
}:

let
  maven360 = maven3.overrideAttrs (oldAttrs: rec {
    _pname = "maven";
    pname = "apache-${_pname}";
    majorVersion = "3";
    version = "${majorVersion}.6.0";

    src = fetchurl {
      url = "https://archive.apache.org/dist/${_pname}/${_pname}-${majorVersion}/${version}/binaries/${pname}-${version}-bin.tar.gz";
      sha256 = "0ds61yy6hs7jgmld64b65ss6kpn5cwb186hw3i4il7vaydm386va";
    };

    jdk = openjdk8_headless;
  });
  maven = maven360;
in (javaPackages.mavenfod.override {
  inherit maven;
}) rec {
  pname = "modelio";
  version1 = "5";
  version2 = "1";
  version3 = "0";
  version12 = "${version1}.${version2}";
  version = "${version12}.${version3}";

  src = fetchFromGitHub {
    owner = "modelioopensource";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-+9dJuP+MzUZdzyjdjzgWNa5AyCv2U0Pz6v8MkBta4Gk=";
  };

  mvnSha256 = "6U1iDAcUMMQUH1FiYtoVhnU62rzZPqFkCZcZRpwqN8g=";
  # mvnParameters = "";

  patches = [
    # Build fails because of
    # missing directories declared in build.properties' bin.includes.
    # bin.includes value(s) [*/] do not match any files.
    # https://github.com/ModelioOpenSource/Modelio/issues/38
    (fetchpatch {
      name = "build-properties-remove-non-existent-directories-from-bin-includes.patch";
      url = "https://github.com/yuuyins/Modelio/commit/04fdda793f8ef191ff11ae9f633e07c052fc28bc.patch";
      sha256 = "sha256-S8KqfRtzf1fHi9gFyQiG3iHuhUxNyk0XcSqBnSCNsWs=";
    })
  ];

  nativeBuildInputs = [
    eclipse-sdk
    maven
    openjdk8_headless
  ];

  buildInputs = [
    atk # libatk
    cairo # libcairo
    freetype # libfreetype.so.6
    gcc # stdc++ 6
    glib # libglib2
    glibc # libc6
    gtk2 # libgtk2
    jre8 # java 8
    libXtst # libxtst6
    # modelio/app/app.script.ui/res/macros/*.py
    # modelio/platform/platform.script.engine/res/*.py
    python
    # modelio/{app,platform}/.*.js
    # doc/plugins/.*.js
    # javascript
    swt #
    webkitgtk # libwebkitgtk-1.0
  ];

  JAVA_HOME = openjdk8_headless.home;
  LANG = "C.UTF-8";
  LC_ALL = "C.UTF-8";
  # mvnParameters = "--errors --debug";

  preInstall = ''
    find $NIX_BUILD_TOP/${src.name}
  '';

  installPhase = if stdenv.hostPlatform.isLinux then ''
    runHook preInstall

    mkdir --parents $out/bin

    install -D --mode=644 \
      $NIX_BUILD_TOP/${src.name}/products/target/products/org.modelio.product/linux/gtk/x86_64/Modelio ${version12}/* \
      --target-directory=$out/

    # ln --symbolic $out/usr/lib/modelio-open-source${version}/modelio $out/bin/modelio
    # ln --symbolic $out/usr/lib/modelio-open-source${version}/modelio.sh $out/bin/modelio.sh

    # rm --recursive --force $out/usr/lib/modelio-open-source${version}/jre
    # ln --symbolic ${jre8.home}/jre $out/usr/lib/modelio-open-source${version}/jre

    runHook postInstall
  '' else if stdenv.hostPlatform.isDarwin then ''
    # $NIX_BUILD_TOP/${src.name}/products/target/products/org.modelio.product/macosx/cocoa/x86_64/Modelio ${version12}.app/
  '' else if stdenv.hostPlatform.isWindows then ''
    # $NIX_BUILD_TOP/${src.name}/products/target/products/org.modelio.product/win32/win32/x86_64/Modelio ${version12}/
  '' else ''
    #
  '';

  meta = with lib; {
    description = "Free, extensible modeling environment for UML and BPMN";
    homepage = "https://www.modelio.org/";
    changelog = "https://github.com/ModelioOpenSource/Modelio/releases";
    license = licenses.gpl3;
    platforms = [
      "x86_64-darwin"
      "x86_64-linux"
      "x86_64-windows"
    ];
    maintainers = with maintainers; [
      yuu
    ];
  };
}
