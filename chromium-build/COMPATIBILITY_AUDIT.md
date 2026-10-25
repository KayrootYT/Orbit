# Orbit Chromium Compatibility Audit

Date: 2026-10-25

## Scope and safety

This is a preliminary compatibility audit based on the current repository workflows and the published Chromium/Bare build documentation. It is deliberately non-destructive: the existing Orbit APK workflow and `Orbit.zip` have not been replaced or modified by this audit.

## Current Orbit build status

- Existing workflow: `.github/workflows/orbit-android-apk.yml`
- Input project: `Orbit.zip`
- Build command: Gradle `assembleDebug`
- Latest observed run at audit time: [run 40158299089](https://github.com/KayrootYT/Orbit/actions/runs/40158299089) — completed successfully, including APK collection and artifact upload.
- Keep this workflow as the stable fallback while evaluating Chromium.

## Chromium workflow status

- Workflow: `.github/workflows/chromium-android.yml`
- Runner requirement: `[self-hosted, linux, x64]`
- It checks for at least 100 GB free disk before building.
- Script: `chromium-build/build_chromium_android.sh`
- Build target: upstream `chrome_public_apk`, staged as `Chromium-Android-ARM64.apk`.

Important: this script fetches upstream Chromium and builds its `ChromePublic.apk`. The script itself explicitly says that it does **not** produce a branded Orbit browser or integrate Orbit's UI/privacy features. The workflow also cannot run on a standard GitHub-hosted runner because it requires a self-hosted runner.

## Bare Browser compatibility

Bare is a patch series against a specific pinned Chromium Android Desktop revision, not a drop-in Android library or an AAR that can simply be added to Orbit's Gradle dependencies. Its build process fetches Chromium source, checks out a matching revision, syncs dependencies, applies the patch series, adds the separately supplied uBlock Origin asset, and then compiles Chromium.

Bare's published build instructions state that Chromium requires around 100 GB free disk; Bare additionally describes a Docker/Linux build environment and recommends at least 32 GB of memory allocated to the VM. The upstream Chromium instructions recommend more than 16 GB RAM and at least 100 GB disk.

Therefore, copying Bare's patches or its APK into the current Orbit project is **not** a safe or complete integration method. A prebuilt Bare APK is a separate application, not an embeddable browser engine for Orbit.

## Compatibility findings

| Area | Finding | Safe next action |
|---|---|---|
| Existing Orbit Gradle project | Current workflow successfully compiles the project packaged in `Orbit.zip`; this does not by itself prove source-level compatibility with Chromium | Preserve current workflow and artifact as baseline |
| Chromium engine | Current Chromium script builds stock Chromium APK separately | Do not label this as Orbit Chromium integration |
| Bare patches | Tied to a pinned Chromium source revision and build configuration | Evaluate as a separate engine migration/fork, not a Gradle dependency |
| Build capacity | Current Chromium workflow requires a self-hosted Linux x64 runner with 100 GB free disk | Do not trigger full build until a suitable runner is configured |
| Orbit UI and features | No evidence from the current workflow that Orbit UI/features are merged into Chromium | Plan an explicit integration layer and verify it in source and APK |
| Signing and package identity | A Chromium APK is not automatically a drop-in replacement for Orbit; package ID, signing key, app entry points, and permissions must be aligned intentionally | Decide package identity and signing strategy before packaging |

## Recommended non-breaking migration plan

1. Keep `.github/workflows/orbit-android-apk.yml` unchanged as the fallback build.
2. Keep Chromium experiments isolated under `chromium-build/` until source-level compatibility is established.
3. Before integrating any Chromium fork, inspect the actual source extracted from `Orbit.zip`: Gradle modules, application ID, minimum SDK, manifest, browser/navigation abstractions, and any WebView-specific APIs.
4. Choose a pinned Chromium/Bare revision and record its license, patches, extension assets, build flags, and required toolchain.
5. Implement Orbit's UI and browser features against a defined engine adapter; do not assume Android WebView APIs are interchangeable with Chromium's internal Android APIs.
6. Build and verify a separate experimental artifact first. Check package ID, ABI, installation, launch, navigation, downloads, permissions, and crash logs.
7. Only after those checks pass, consider switching a workflow. Preserve the existing APK workflow until the new pipeline repeatedly produces a verified Orbit-branded APK.

## Audit limitation

This report is a workflow/documentation-level compatibility assessment. It is **not** a claim that Bare has been merged into Orbit, that the Chromium engine is integrated, or that a new Chromium-based Orbit APK has been built. The next source-level step is to inspect the project files inside `Orbit.zip` before proposing code changes.
