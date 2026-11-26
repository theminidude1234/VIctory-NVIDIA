#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$base = '7480e961a5a1f8665d5ce17baa624f4d26e5f44e'
$expectedPatchHash = '80778a8d882b32d560a5df668bbb37897971ed3b298776ef502bf6a02dad2507'
$expectedTree = '936003e7fc099689ddd8432bf81664481805f5e0'
$backupDir = $PSScriptRoot
$repo = $PSScriptRoot
$partPrefix = 'VIctory-RTX4070S-integration.patch.gz.b64.part'
$gzipPath = Join-Path $env:TEMP 'VIctory-RTX4070S-integration.patch.gz'
$patchPath = Join-Path $env:TEMP 'VIctory-RTX4070S-integration.patch'

Set-Location $repo
if (@(git status --porcelain).Count -ne 0) {
    throw 'The repository is not clean. Run this restorer from a fresh backup-branch clone.'
}
git cat-file -e "$base^{commit}"
if ($LASTEXITCODE -ne 0) { throw "Original base commit $base is unavailable." }

$parts = @(Get-ChildItem -LiteralPath $backupDir -Filter "$partPrefix*" | Sort-Object Name)
if ($parts.Count -ne 16) {
    throw "Expected 16 backup transport parts but found $($parts.Count)."
}
$encoded = ($parts | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join ''
[IO.File]::WriteAllBytes($gzipPath, [Convert]::FromBase64String($encoded))
$inputStream = [IO.File]::OpenRead($gzipPath)
$gzip = [IO.Compression.GzipStream]::new($inputStream, [IO.Compression.CompressionMode]::Decompress)
$output = [IO.File]::Create($patchPath)
try {
    $gzip.CopyTo($output)
} finally {
    $output.Dispose()
    $gzip.Dispose()
    $inputStream.Dispose()
}

$actualPatchHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $patchPath).Hash.ToLowerInvariant()
if ($actualPatchHash -ne $expectedPatchHash) {
    throw "Patch checksum mismatch. Expected $expectedPatchHash but got $actualPatchHash."
}

git checkout -b integration/rtx4070-super-restored $base
if ($LASTEXITCODE -ne 0) { throw 'Could not create the local restoration branch.' }
git apply --binary --check $patchPath
if ($LASTEXITCODE -ne 0) { throw 'The integration patch does not apply cleanly.' }
git apply --binary $patchPath
if ($LASTEXITCODE -ne 0) { throw 'The integration patch failed to apply.' }
git add -A
if ($LASTEXITCODE -ne 0) { throw 'Could not stage the restored source.' }
$tree = (git write-tree).Trim()
if ($tree -ne $expectedTree) {
    throw "Tree verification failed. Expected $expectedTree but got $tree."
}

Write-Host "Restored and staged the exact integrated tree $tree." -ForegroundColor Green
Write-Host 'No commit or remote push was made. Inspect the changes, then follow RTX4070S-SETUP.md.'
Write-Host "Verified patch retained at $patchPath"
