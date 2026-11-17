param([string]$Target = 'help')
# Windows PowerShell 5.1+, native MinGW-w64 GCC; no sh/awk/MSYS dependency.
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
if ($Target -eq 'help') {
    Write-Output @'
Exercise 5 native C17
make help/check/examples/all/test-a/test-b/test/example-adder/example-alu/test-student/clean
check: native C17 compile/link/run; examples: supplied parts only
all: supplied parts and build checks (unfinished tasks allowed)
test-b: XOR/FA dependencies, then ALU1/ALU32; RCA is not a dependency
CC: one executable path; default gcc. CFLAGS: whitespace-separated flags, default -O0 -g
tools/run.ps1 can also be called directly to observe the runner exit code.
'@
    exit 0
}
$targets = @('check','examples','all','test-a','test-b','test','example-adder','example-alu','test-student','clean')
if ($targets -notcontains $Target) { Write-Output '[ENV] unknown target'; exit 2 }
function Assert-RealDirectory([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path -Force
        if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "[ENV] refusing non-directory or reparse point: $Path"
        }
    }
}
try { Assert-RealDirectory 'build' } catch { Write-Output $_; exit 2 }
if (-not (Test-Path -LiteralPath 'build')) { [void](New-Item -ItemType Directory -Path 'build') }
if ($Target -eq 'clean') {
    $items = @(Get-ChildItem -LiteralPath 'build' -Force | Where-Object { $_.Name -like 'run-*' })
    try {
        foreach ($item in $items) {
            Assert-RealDirectory $item.FullName
            $links = @(Get-ChildItem -LiteralPath $item.FullName -Force -Recurse |
                Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
            if ($links.Count) { throw '[ENV] refusing reparse point inside build' }
        }
        foreach ($item in $items) { Remove-Item -LiteralPath $item.FullName -Force -Recurse }
    } catch { Write-Output $_; exit 2 }
    Write-Output '[PASS] clean (student files and build/.gitkeep retained)'
    exit 0
}
$run = 'build/run-' + [Guid]::NewGuid().ToString('N')
[void](New-Item -ItemType Directory -Path $run)
Write-Output "LOGDIR=$run"
function Read-Limit([string]$Name, [int]$Default, [int]$Minimum) {
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrEmpty($value)) { return $Default }
    $number = 0
    if (-not [int]::TryParse($value,[ref]$number) -or $number -lt $Minimum) {
        throw "[ENV] invalid $Name"
    }
    return $number
}
try {
    $buildSeconds = Read-Limit 'EX05_BUILD_TIMEOUT' 120 1
    $seconds = Read-Limit 'EX05_RUN_TIMEOUT' 20 1
    $limit = Read-Limit 'EX05_OUTPUT_LIMIT' 1048576 1024
    $compiler = $env:CC
    if ([string]::IsNullOrWhiteSpace($compiler)) { $compiler = 'gcc' }
    $resolved = Get-Command -Name $compiler -CommandType Application -ErrorAction Stop
    $ccPath = $resolved.Source
    $env:PATH = (Split-Path -Parent $ccPath) + ';' + $env:PATH
} catch { Write-Output "[ENV] CC/limits invalid; no fallback: $_"; exit 2 }
$cflags = if ([string]::IsNullOrWhiteSpace($env:CFLAGS)) { @('-O0','-g') } else { @($env:CFLAGS -split '\s+' | Where-Object { $_ }) }
$ldflags = if ([string]::IsNullOrWhiteSpace($env:LDFLAGS)) { @() } else { @($env:LDFLAGS -split '\s+' | Where-Object { $_ }) }
@("CC=$ccPath","CFLAGS=$($cflags -join ' ')","LDFLAGS=$($ldflags -join ' ')") |
    Set-Content -LiteralPath "$run/config.txt" -Encoding UTF8
function Quote-Argument([string]$Value) {
    return '"' + [regex]::Replace([regex]::Replace($Value,'(\\*)"','$1$1\"'),'(\\+)$','$1$1') + '"'
}
function Stop-OwnedTree([int]$ParentId) {
    $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$ParentId" -ErrorAction SilentlyContinue)
    foreach ($child in $children) { Stop-OwnedTree ([int]$child.ProcessId) }
    Stop-Process -Id $ParentId -Force -ErrorAction SilentlyContinue
}
$guard = "$run/guard.exe"
$bootstrapArgs = @('-std=c17','-Wall','-Wextra','-Wpedantic','tools/guard.c','-lshell32','-o',$guard)
$bootstrap = $null
try {
    $argumentLine = ($bootstrapArgs | ForEach-Object { Quote-Argument $_ }) -join ' '
    $bootstrap = Start-Process -FilePath $ccPath -ArgumentList $argumentLine -NoNewWindow -PassThru -RedirectStandardOutput "$run/bootstrap.stdout" -RedirectStandardError "$run/bootstrap.stderr"
    "pid=$($bootstrap.Id)" | Set-Content "$run/bootstrap.meta"
    if (-not $bootstrap.WaitForExit($buildSeconds * 1000)) {
        Stop-OwnedTree $bootstrap.Id
        $bootstrap.WaitForExit()
        throw '[ENV] compiler bootstrap timeout'
    }
    $bootstrap.WaitForExit()
    "raw_exit=$($bootstrap.ExitCode)" | Add-Content "$run/bootstrap.meta"
    if ($bootstrap.ExitCode -ne 0) { throw '[ENV] cannot build native monitor; check compiler' }
} catch {
    if (Test-Path "$run/bootstrap.stderr") { Get-Content "$run/bootstrap.stderr" }
    Write-Output $_
    exit 2
} finally {
    if ($null -ne $bootstrap) {
        if (-not $bootstrap.HasExited) { Stop-OwnedTree $bootstrap.Id; $bootstrap.WaitForExit() }
        $bootstrap.Dispose()
    }
}
$script:serial = 0
$script:childRC = 0
function Invoke-Monitored([string]$Label,[string]$Completion,[int]$Duration,[string[]]$Command) {
    $script:serial++
    $prefix = '{0}/{1:D3}-{2}' -f $run,$script:serial,$Label
    try {
        & $guard run "$Duration" "$limit" $prefix $Completion @Command
        $script:childRC = $LASTEXITCODE
    } catch { Write-Output "[RUNTIME] cannot execute native monitor: $_"; $script:childRC = 7 }
    if (Test-Path "$prefix.stdout") { [Console]::Write([IO.File]::ReadAllText((Join-Path (Get-Location) "$prefix.stdout"))) }
    if (Test-Path "$prefix.stderr") { [Console]::Error.Write([IO.File]::ReadAllText((Join-Path (Get-Location) "$prefix.stderr"))) }
}
function Build-Program([string]$Label,[string]$Output,[string[]]$Sources) {
    $command = @($ccPath,'-std=c17','-Wall','-Wextra','-Wpedantic') + $cflags +
               @('-Iinclude','-Itests') + $Sources + $ldflags + @('-o',$Output)
    Invoke-Monitored "build-$Label" '-' $buildSeconds $command
    if ($script:childRC -ne 0) { Write-Output "[BUILD] $Label compilation/link failed"; $script:childRC = 4 }
}
Invoke-Monitored 'compiler-version' '-' $buildSeconds @($ccPath,'--version') | Out-File "$run/compiler.txt" -Encoding UTF8
if ($script:childRC -ne 0) { Write-Output '[ENV] compiler version query failed'; exit 2 }
Invoke-Monitored 'compiler-target' '-' $buildSeconds @($ccPath,'-dumpmachine') | Out-File "$run/target.txt" -Encoding UTF8
if ($script:childRC -ne 0) { Write-Output '[ENV] compiler target query failed'; exit 2 }
Build-Program 'probe' "$run/probe.exe" @('tools/probe.c')
if ($script:childRC -ne 0) { Write-Output '[ENV] native C17 probe did not build'; exit 2 }
Invoke-Monitored 'check' 'check' $seconds @("$run/probe.exe")
if ($script:childRC -ne 0) { Write-Output '[ENV] generated C17 executable did not run correctly'; exit 2 }
if ($Target -eq 'check') { exit 0 }
$sourcePreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $guard source 1> "$run/source.stdout" 2> "$run/source.stderr"
$sourceRC = $LASTEXITCODE
$ErrorActionPreference = $sourcePreference
Get-Content "$run/source.stdout"
Get-Content "$run/source.stderr"
if ($sourceRC -ne 0) { exit 8 }
$common = @('src/gates.c','src/mux.c','src/word.c','tasks/adder_task.c','tasks/alu_task.c','tests/test_support.c')
$testSources = $common + @('tests/test_parts.c','tests/test_adder.c','tests/test_alu.c','tests/student_cases.c','tests/test_main.c')
Build-Program 'tests' "$run/tests.exe" $testSources
if ($script:childRC -ne 0) { exit 4 }
if ($Target -in @('all','examples')) {
    Build-Program 'example-gates' "$run/example-gates.exe" ($common + @('tests/test_parts.c','examples/gates_and_wires.c'))
    if ($script:childRC -ne 0) { exit 4 }
    if ($Target -eq 'all') {
        Build-Program 'example-adder' "$run/example-adder.exe" ($common + @('examples/observe_adder.c'))
        if ($script:childRC -ne 0) { exit 4 }
        Build-Program 'example-alu' "$run/example-alu.exe" ($common + @('examples/observe_alu.c'))
        if ($script:childRC -ne 0) { exit 4 }
    }
    Invoke-Monitored 'example-gates' 'example-gates' $seconds @("$run/example-gates.exe")
    if ($script:childRC -ne 0) { exit $script:childRC }
    Write-Output '[PASS] supplied parts; examples 2/3 require task implementations.'
    Write-Output 'Use make example-adder / make example-alu after implementing the tasks.'
    exit 0
}
if ($Target -in @('example-adder','example-alu')) {
    $driver = if ($Target -eq 'example-adder') { 'examples/observe_adder.c' } else { 'examples/observe_alu.c' }
    Build-Program $Target "$run/$Target.exe" ($common + @($driver))
    if ($script:childRC -ne 0) { exit 4 }
    Invoke-Monitored $Target $Target $seconds @("$run/$Target.exe")
    exit $script:childRC
}
function Run-Group([string]$Name) { Invoke-Monitored $Name $Name $seconds @("$run/tests.exe",$Name) }
$status = 0
Run-Group 'parts'
if ($script:childRC -ne 0) { Write-Output '[DEPENDENCY] supplied parts failed; A/B skipped, cases=0'; exit 9 }
Run-Group 'xor'; $xorRC = $script:childRC
if ($xorRC -eq 0) { Run-Group 'fa'; $faRC = $script:childRC }
else { $faRC = 9; Write-Output '[DEPENDENCY] fa skipped: XOR failed; cases=0' }
if ($xorRC -ne 0 -or $faRC -ne 0) { $status = 9 }
if ($Target -in @('test-a','test','test-student')) {
    if ($faRC -eq 0) { Run-Group 'rca'; $rcaRC = $script:childRC }
    else { $rcaRC = 9; Write-Output '[DEPENDENCY] rca skipped: FA failed; cases=0' }
    if ($rcaRC -ne 0) { $status = 9 }
    Write-Output "SUMMARY A xor=$xorRC fa=$faRC rca=$rcaRC"
}
if ($Target -in @('test-b','test','test-student')) {
    if ($faRC -eq 0) {
        Run-Group 'alu1'; $alu1RC = $script:childRC
        if ($alu1RC -eq 0) { Run-Group 'alu32'; $alu32RC = $script:childRC }
        else { $alu32RC = 9; Write-Output '[DEPENDENCY] alu32 skipped: ALU1 failed; cases=0' }
    } else {
        $alu1RC = 9; $alu32RC = 9
        Write-Output '[DEPENDENCY] ALU1/ALU32 skipped: XOR/FA failed (RCA not required); cases=0'
    }
    if ($alu1RC -ne 0 -or $alu32RC -ne 0) { $status = 9 }
    Write-Output "SUMMARY B alu1=$alu1RC alu32=$alu32RC"
}
if ($Target -eq 'test-student') {
    if ($rcaRC -eq 0) { Run-Group 'student-a'; if ($script:childRC -ne 0) { $status = 9 } }
    else { Write-Output '[DEPENDENCY] student-a skipped; cases=0' }
    if ($alu32RC -eq 0) { Run-Group 'student-b'; if ($script:childRC -ne 0) { $status = 9 } }
    else { Write-Output '[DEPENDENCY] student-b skipped; cases=0' }
}
if ($status -eq 0) { Write-Output "[PASS] $Target completed" }
exit $status
