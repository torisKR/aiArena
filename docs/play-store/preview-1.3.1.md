# Android build-only preview 1.3.1

- Restore explicit `com.google.android.gms.permission.AD_ID` to match the owner's current advertising-ID use declaration. No Play Console declarations are changed.
- Preserve UMP gating and explicit `AdRequest(nonPersonalizedAds: true)` for all formats. Non-personalized ads can still process identifiers; correct the obsolete no-ID claim and test-only descriptions.
- Package full-resolution WebP copies of the splash and key art, encoded with `cwebp -q 88 -m 6`. Source PNGs remain unchanged. Key-art alpha was fully opaque (255–255); the transparency-dependent token atlas is unchanged.
- Explicit Flutter asset entries exclude the unused runtime logo source and source artwork. The logo remains the icon-generation input. Preserve the two-second launch splash, localized Korean title and generated Android icons.
- Version name is 1.3.1. CI allocates a Unix-time version code strictly greater than 1789986566 and less than 2100000000; pubspec's fallback is 1789986567.
- Billing/account configuration remains absent and purchase gates remain disabled. This workflow builds and retains an AAB only; it does not upload to Play, deploy a backend, or publish policies.

## Size interpretation

The previous AAB is 65,613,390 bytes. Its largest contributors include Flutter libraries for three ABIs and build metadata (native symbols and mapping files). Those are not all downloaded to one device. Do not strip useful symbol metadata merely to make the AAB look smaller.

Runtime source artwork before optimization: splash 2,096,907 bytes; unused logo 1,907,050 bytes; key art 1,576,013 bytes. New runtime WebP files: splash 193,226 bytes; key art 76,856 bytes, with original dimensions retained. The asset regression test verifies decodability, dimensions, source-file preservation and source exclusion.

Compare the exact old/new bundles with bundletool-generated device-specific split APKs and its compressed download-size estimate using the same device spec. This is an estimate, not Play's final served download or post-install disk footprint. No device installation is required or authorized for this build. A Play size warning may persist; only processing of the new artifact can establish the Console result.
