{
  lib,
  rustPlatform,
  fetchFromGitHub,

  jq,
  moreutils,
  pnpm_8,
  fetchPnpmDeps,
  pnpmConfigHook,
  nodejs,
  cargo-tauri,
  pkg-config,
  wrapGAppsHook3,

  libsoup_3,
  openssl,
  webkitgtk_4_1,

  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "annot";
  version = "0.9.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "denolehov";
    repo = "annot";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OZqW2H8O7eL8FcZA5A2OaxfpUOiIUMrA/5p0jSoQAx0=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_8;
    fetcherVersion = 3;
    hash = "sha256-vzvD/0tWoZYCHrbAhrkGDNKXkE9cq5SKCX46IKH1rdE=";
  };

  postPatch = ''
    jq '.bundle.createUpdaterArtifacts = false' src-tauri/tauri.conf.json | sponge src-tauri/tauri.conf.json
  '';

  cargoRoot = "src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  cargoHash = "sha256-WwTqo1ytiDIMsf0+dlkHYq4xNg5t/ba34vKtxlsxdN0=";

  nativeBuildInputs = [
    jq
    moreutils
    pnpmConfigHook
    pnpm_8
    nodejs
    cargo-tauri.hook
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    libsoup_3
    openssl
    webkitgtk_4_1
  ];

  # pnpmConfigHook runs with --ignore-scripts, so the postinstall that copies
  # Excalidraw fonts from node_modules into static/ must be run manually.
  preBuild = ''
    node scripts/copy-excalidraw-fonts.js
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Human-in-the-loop annotation tool for AI workflows";
    longDescription = ''
      annot is an annotation tool for human-in-the-loop AI workflows. AI
      agents work fast, but vague feedback is a lossy channel. When an agent
      drafts a plan, proposes a refactor, or generates code, annot provides a
      moment of structured review: it opens a native window, you annotate
      specific lines with located, typed comments, then it closes and returns
      structured output to the agent.

      annot can be used as a standalone CLI (open a file, annotate, get
      output) or as an MCP server, allowing AI agents to block on human
      review mid-workflow. It supports reviewing files, diffs, and
      agent-generated content, with optional exit modes so the human can
      signal approval, rejection, or custom next steps.
    '';
    homepage = "https://github.com/denolehov/annot";
    license = lib.licenses.agpl3Only;
    mainProgram = "annot";
    #maintainers = [ fraggerfox ];
    platforms = lib.platforms.linux;
  };
})
