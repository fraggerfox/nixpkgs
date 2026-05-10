{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  autoreconfHook,
  libsndfile,
  freeglut,
  libGL,
  libGLU,
  libjpeg,
  SDL,
  tcl,

  # Audio backend — exactly one must be selected.
  # ALSA is the upstream-recommended Linux backend; JACK is used elsewhere.
  jackSupport ? !stdenv.hostPlatform.isLinux,
  jack2,
  alsaSupport ? stdenv.hostPlatform.isLinux,
  alsa-lib,
}:

assert lib.assertMsg (
  lib.count (x: x) [
    jackSupport
    alsaSupport
  ] == 1
) "din: exactly one audio backend must be selected (jackSupport or alsaSupport)";

stdenv.mkDerivation (finalAttrs: {
  pname = "din";
  version = "64.2";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchurl {
    url = "https://dinisnoise.org/files/din-${finalAttrs.version}.tar.gz";
    hash = "sha256-YpaGOAVJmUMDkqvu9+fzW1RbNNSRO2Id8zg8DIblGXE=";
  };

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
  ];

  buildInputs = [
    libsndfile
    freeglut
    libGL
    libGLU
    libjpeg
    SDL
    tcl
  ]
  ++ lib.optionals jackSupport [ jack2 ]
  ++ lib.optionals alsaSupport [ alsa-lib ];

  # Makefile.am hard-codes /usr/include/tcl8.6 and unconditionally links
  # -lasound. Strip both so Nix controls all flags via configureFlags.
  preConfigure = ''
    substituteInPlace src/Makefile.am \
      --replace-fail "-I /usr/include/tcl8.6" "-I${tcl}/include" \
      --replace-fail " -lasound" ""
  '';

  # Pass the backend macro and linker flags via configure, matching the
  # upstream build scripts (o3-alsa / o3-jack).
  configureFlags =
    lib.optional jackSupport "CXXFLAGS=-D__UNIX_JACK__"
    ++ lib.optional alsaSupport "CXXFLAGS=-D__LINUX_ALSA__"
    ++ lib.optional jackSupport "LIBS=-ljack"
    ++ lib.optional alsaSupport "LIBS=-lasound";

  enableParallelBuilding = true;

  meta = {
    description = "Open source cross-platform sound synthesizer";
    longDescription = ''
      DIN Is Noise is a program for making sound, music and noise. Use bezier
      curves to edit waveforms, envelopes, modulators and FX components; use
      the keyboard (computer and MIDI) to trigger notes (or noise), use the
      mouse to sound like the theremin, create drones on microtones, launch,
      orbit and drag them around; bounce balls on walls to trigger notes in a
      mondrian inspired drawing and also make binaural beats. Supports MIDI
      input and scripting through TCL.
    '';
    homepage = "https://dinisnoise.org/";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ fraggerfox ];
    platforms = lib.platforms.linux;
    mainProgram = "din";
  };
})
