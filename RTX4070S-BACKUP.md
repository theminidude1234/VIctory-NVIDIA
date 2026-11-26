# RTX 4070 Super integration backup

This branch stores the complete integrated source change as a compressed, Base64-encoded Git binary patch, split into 16 transport parts. It does not modify `main`, and it contains no game files or assets.

The normal source branch could not be transported directly because the available GitHub connection supports file writes but the shell has no Git push credential. This backup preserves the exact final tree and can restore it locally.

## Restore on Windows

Clone this backup branch, then run the restorer from a normal PowerShell window:

```powershell
git clone --branch integration/rtx4070-super-backup https://github.com/theminidude1234/VIctory-NVIDIA.git
cd VIctory-NVIDIA
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Restore-RTX4070S.ps1
```

The script:

1. Decompresses the patch into the temporary directory.
2. Verifies its SHA-256 hash.
3. Creates local branch `integration/rtx4070-super-restored` from the original base commit.
4. Applies the binary-capable patch.
5. Stages the restored source and verifies the complete Git tree hash.
6. Stops before committing or pushing, so the result can be inspected first.

Expected values:

```text
Base commit: 7480e961a5a1f8665d5ce17baa624f4d26e5f44e
Patch SHA256: 80778a8d882b32d560a5df668bbb37897971ed3b298776ef502bf6a02dad2507
Final tree: 936003e7fc099689ddd8432bf81664481805f5e0
Changed files: 48
Insertions: 14,027
Deletions: 823
```

After restoration, follow `RTX4070S-SETUP.md` in the restored tree. The patch recreates the integrated file contents, not the temporary local commit history.

Validation before packaging:

- Shader tests: 233 passed, 0 failed, 2 ignored, both normally and with diagnostics.
- Windows GPU library and tests cross-check: passed, normally and with diagnostics.
- Complete Windows application cross-check with diagnostics: passed.
- `git diff --check`: passed.
- ZIP integrity and reverse-patch checks: passed.
- Actual RTX 4070 Super rendering, stability, and frame rate remain unverified.
