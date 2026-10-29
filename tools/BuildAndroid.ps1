[CmdletBinding()]
param(
    [ValidateSet('Check', 'Prepare', 'Update', 'Typecheck', 'Build', 'Test')]
    [string]$Action = 'Check',
    [ValidateSet('ARMv7', 'ARM64', 'Universal')]
    [string]$Architecture = 'ARM64',
    [string]$SdkPath = "$env:USERPROFILE\AppData\Local\Android\Sdk",
    [string]$JdkPath = "$env:USERPROFILE\Documents\AndroidTools\jdk-17.0.20.1+1",
    [string]$HxcppPath = "$env:USERPROFILE\Documents\AndroidTools\hxcpp-4.3.175",
    [ValidateRange(512, 16384)]
    [int]$GradleHeapMB = 4096,
    [switch]$Release
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$profileRoot = Join-Path $projectRoot 'export\android-local'
$profileLibraries = Join-Path $profileRoot '.haxelib'
$desktopLibraries = Join-Path $projectRoot '.haxelib'
$ndkPath = Join-Path $SdkPath 'ndk\21.4.7075529'
$pathEncoding = New-Object System.Text.UTF8Encoding($false)
$targetArchitectures = switch ($Architecture) {
    'ARMv7' { @('armv7') }
    'ARM64' { @('arm64') }
    'Universal' { @('armv7', 'arm64') }
}

foreach ($requiredFile in @(
    (Join-Path $JdkPath 'bin\java.exe'),
    (Join-Path $SdkPath 'platform-tools\adb.exe'),
    (Join-Path $SdkPath 'platforms\android-30\android.jar'),
    (Join-Path $SdkPath 'build-tools\30.0.3\aapt.exe'),
    (Join-Path $ndkPath 'source.properties'),
    (Join-Path $HxcppPath 'haxelib.json'),
    (Join-Path $HxcppPath 'run.n'),
    (Join-Path $HxcppPath 'hxcpp.n')
)) {
    if (!(Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required Android build file was not found: $requiredFile"
    }
}
foreach ($command in @('haxe', 'haxelib', 'neko')) {
    $null = Get-Command $command -ErrorAction Stop
}
$hxcppMetadata = Get-Content -LiteralPath (Join-Path $HxcppPath 'haxelib.json') -Raw | ConvertFrom-Json
if ($hxcppMetadata.version -ne '4.3.175') {
    throw "Expected Android hxcpp 4.3.175, found $($hxcppMetadata.version)."
}
$desktopHxcppRoot = Join-Path $desktopLibraries 'hxcpp'
$desktopHxcppDev = Join-Path $desktopHxcppRoot '.dev'
if (Test-Path -LiteralPath $desktopHxcppDev) {
    $desktopHxcppPath = (Get-Content -LiteralPath $desktopHxcppDev -Raw).Trim()
} else {
    $desktopHxcppVersion = (Get-Content -LiteralPath (Join-Path $desktopHxcppRoot '.current') -Raw).Trim()
    $desktopHxcppPath = Join-Path $desktopHxcppRoot ($desktopHxcppVersion.Replace('.', ','))
}
if ([System.IO.Path]::GetFullPath($desktopHxcppPath).TrimEnd('\', '/') -eq
    [System.IO.Path]::GetFullPath($HxcppPath).TrimEnd('\', '/')) {
    throw 'Android hxcpp must be separate from the active Windows hxcpp installation.'
}

# NDK r21's libc++ does not expose atomic<T>::value_type. common_type<T>::type
# preserves the same type and non-deduced argument conversions (including an
# int literal passed to atomic<unsigned int>), without changing CAS semantics.
# Only the dedicated Android hxcpp installation is patched; retain its original.
if ($Action -in @('Prepare', 'Build', 'Test')) {
    $immixPath = Join-Path $HxcppPath 'src\hx\gc\Immix.cpp'
    $immixSource = [System.IO.File]::ReadAllText($immixPath)
    $oldType = 'typename std::atomic<T>::value_type'
    $newType = 'typename std::common_type<T>::type'
    if ($immixSource.Contains($oldType)) {
        if (!$immixSource.Contains('bool atomic_compare_exchange_strong_discard(std::atomic<T>* obj,') -or
            ([regex]::Matches($immixSource, [regex]::Escape($oldType))).Count -ne 3) {
            throw 'Android hxcpp atomic helper differs from the expected 4.3.175 source; refusing to patch it.'
        }
        $backupPath = "$immixPath.icu-ndk21.original"
        if (!(Test-Path -LiteralPath $backupPath)) {
            [System.IO.File]::WriteAllBytes($backupPath, [System.IO.File]::ReadAllBytes($immixPath))
        }
        $patchedSource = $immixSource.Replace($oldType, $newType)
        if (!$patchedSource.Contains('#include <type_traits>')) {
            $patchedSource = $patchedSource.Replace('#include <inttypes.h>', "#include <inttypes.h>`n#include <type_traits>")
        }
        [System.IO.File]::WriteAllText($immixPath, $patchedSource, $pathEncoding)
        Write-Host 'Applied hxcpp 4.3.175 / NDK r21 atomic type compatibility fix (original backed up).'
    } elseif (!$immixSource.Contains($newType)) {
        throw 'Unable to recognize the Android hxcpp atomic helper.'
    }
    $gcCommonPath = Join-Path $HxcppPath 'src\hx\gc\GcCommon.cpp'
    $gcCommonSource = [System.IO.File]::ReadAllText($gcCommonPath)
    if (!$gcCommonSource.Contains('#include <cstdio>')) {
        if (!$gcCommonSource.Contains('#include <hxcpp.h>') -or !$gcCommonSource.Contains('std::sscanf(')) {
            throw 'Android hxcpp GcCommon.cpp differs from the expected source; refusing to patch it.'
        }
        $backupPath = "$gcCommonPath.icu-ndk21.original"
        if (!(Test-Path -LiteralPath $backupPath)) {
            [System.IO.File]::WriteAllBytes($backupPath, [System.IO.File]::ReadAllBytes($gcCommonPath))
        }
        $patchedSource = $gcCommonSource.Replace('#include <hxcpp.h>', "#include <hxcpp.h>`n#include <cstdio>")
        [System.IO.File]::WriteAllText($gcCommonPath, $patchedSource, $pathEncoding)
        Write-Host 'Applied hxcpp GcCommon.cpp missing <cstdio> include fix (original backed up).'
    }
}

# Each .dev file points at an existing library. Nothing is copied or switched
# in the project's Windows repository. All Android build children remain under
# this profile so haxelib also resolves it from the generated C++ directory.
$null = New-Item -ItemType Directory -Path $profileLibraries -Force
$resolvedLibraries = @{}
foreach ($library in Get-ChildItem -LiteralPath $desktopLibraries -Directory) {
    if ($library.Name -eq 'hxcpp') { continue }
    $devFile = Join-Path $library.FullName '.dev'
    $currentFile = Join-Path $library.FullName '.current'
    if (Test-Path -LiteralPath $devFile) {
        $libraryPath = (Get-Content -LiteralPath $devFile -Raw).Trim()
    } elseif (Test-Path -LiteralPath $currentFile) {
        $version = (Get-Content -LiteralPath $currentFile -Raw).Trim()
        $libraryPath = Join-Path $library.FullName ($version.Replace('.', ','))
    } else { continue }
    if (!(Test-Path -LiteralPath $libraryPath -PathType Container)) {
        throw "Library directory was not found: $libraryPath"
    }
    $resolvedLibraries[$library.Name] = $libraryPath
    $destination = Join-Path $profileLibraries $library.Name
    $null = New-Item -ItemType Directory -Path $destination -Force
    [System.IO.File]::WriteAllText((Join-Path $destination '.dev'), $libraryPath, $pathEncoding)
}
$androidHxcpp = Join-Path $profileLibraries 'hxcpp'
$null = New-Item -ItemType Directory -Path $androidHxcpp -Force
[System.IO.File]::WriteAllText((Join-Path $androidHxcpp '.dev'), $HxcppPath, $pathEncoding)

foreach ($targetArchitecture in $targetArchitectures) {
    $suffix = if ($targetArchitecture -eq 'armv7') { '-v7' } else { '-64' }
    foreach ($nativeFile in @(
        (Join-Path $resolvedLibraries['lime'] "ndll\Android\liblime$suffix.so"),
        (Join-Path $resolvedLibraries['hxvlc'] "project\vlc\lib\Android\libvlc$suffix.so"),
        (Join-Path $resolvedLibraries['hxvlc'] "project\vlc\lib\Android\libc++_shared$suffix.so")
    )) {
        if (!(Test-Path -LiteralPath $nativeFile -PathType Leaf)) {
            throw "Required $targetArchitecture native library was not found: $nativeFile"
        }
    }
}

# Include the live project rather than maintain a second copy of its XML.
$includePath = [System.Security.SecurityElement]::Escape((Join-Path $projectRoot 'project.xml').Replace('\', '/'))
$architectureXml = foreach ($targetArchitecture in @('armv5', 'armv6', 'armv7', 'arm64', 'x86', 'x64')) {
    if ($targetArchitecture -in $targetArchitectures) {
        "    <architecture name=`"$targetArchitecture`" />"
    } else {
        "    <architecture exclude=`"$targetArchitecture`" />"
    }
}
$architectureXml = $architectureXml -join "`n"
$wrapper = @"
<?xml version="1.0" encoding="utf-8"?>
<project>
    <include path="$includePath" />
    <app path="build/debug" if="debug" />
    <app path="build/release" unless="debug" />
    <config:android target-sdk-version="30" minimum-sdk-version="21" build-tools-version="30.0.3" />
$architectureXml
    <haxedef name="HXCPP_ANDROID_PLATFORM" value="21" />
</project>
"@
Set-Content -LiteralPath (Join-Path $profileRoot 'project.xml') -Value $wrapper -Encoding UTF8

$environmentNames = @('JAVA_HOME', 'ANDROID_SDK', 'ANDROID_HOME', 'ANDROID_NDK_ROOT', 'ANDROID_SETUP', 'HAXELIB_PATH', 'HXCPP_COMPILE_THREADS', 'GRADLE_OPTS', 'PATH')
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
try {
    $env:JAVA_HOME = $JdkPath
    $env:ANDROID_SDK = $SdkPath
    $env:ANDROID_HOME = $SdkPath
    $env:ANDROID_NDK_ROOT = $ndkPath
    $env:ANDROID_SETUP = 'true'
    $env:HAXELIB_PATH = $profileLibraries
    $env:PATH = "$JdkPath\bin;$SdkPath\platform-tools;$env:PATH"
    # Keep Gradle in this JVM, avoiding local daemon/socket startup failures.
    # Set the heap on the client JVM: org.gradle.jvmargs is deliberately empty,
    # so setting a daemon heap alone would not configure the process packaging APKs.
    # Append after inherited options so a terminal's older -Xmx does not win.
    $env:GRADLE_OPTS = "$env:GRADLE_OPTS -Xms128m -Xmx${GradleHeapMB}m -Dorg.gradle.daemon=false -Dorg.gradle.jvmargs= -Dorg.gradle.workers.max=2 -Dorg.gradle.parallel=false -Djava.net.preferIPv4Stack=true"
    if (!$env:HXCPP_COMPILE_THREADS) { $env:HXCPP_COMPILE_THREADS = '4' }
    Push-Location -LiteralPath $profileRoot
    try {
        Write-Host "Android Java: $JdkPath"
        Write-Host "Android SDK: $SdkPath"
        Write-Host "Android NDK: $ndkPath"
        Write-Host "Android hxcpp: $HxcppPath ($($hxcppMetadata.version))"
        Write-Host "Android architectures: $($targetArchitectures -join ', ')"
        Write-Host "Android Gradle heap limit: $GradleHeapMB MiB; max workers: 2"
        Write-Host "Android profile: $profileRoot"
        & haxelib libpath hxcpp
        if ($LASTEXITCODE -ne 0) { throw 'Unable to resolve Android hxcpp.' }
        if ($Action -in @('Check', 'Prepare')) { return }

        $limeAction = switch ($Action) {
            'Update' { 'update' }
            'Typecheck' { 'update' }
            'Build' { 'build' }
            'Test' { 'test' }
        }
        $limeArguments = @('run', 'lime', $limeAction, 'android')
        if (!$Release) { $limeArguments += '-debug' }
        & haxelib @limeArguments
        if ($LASTEXITCODE -ne 0) { throw "Android $Action failed (exit code $LASTEXITCODE)." }
        if ($Action -eq 'Typecheck') {
            $configuration = if ($Release) { 'release' } else { 'debug' }
            foreach ($targetArchitecture in $targetArchitectures) {
                $architectureDefine = if ($targetArchitecture -eq 'armv7') { 'HXCPP_ARMV7' } else { 'HXCPP_ARM64' }
                & haxe "build/$configuration/android/haxe/$configuration.hxml" --no-output -D $architectureDefine -D HXCPP_ANDROID_PLATFORM=21
                if ($LASTEXITCODE -ne 0) { throw "Android $targetArchitecture Haxe typecheck failed (exit code $LASTEXITCODE)." }
                Write-Host "Android $targetArchitecture Haxe typecheck passed."
            }
        }
    } finally { Pop-Location }
} finally {
    foreach ($name in $environmentNames) {
        [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process')
    }
}
