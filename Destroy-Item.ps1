param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String] $Path
)

$Script:RNG = [Security.Cryptography.RandomNumberGenerator]::Create()

$Gutmann = @(
    @(0x00),
    @(0x11),
    @(0x22),
    @(0x33),
    @(0x44),
    @(0x55), @(0x55)
    @(0x66),
    @(0x77),
    @(0x88),
    @(0x99),
    @(0xAA), @(0xAA)
    @(0xBB),
    @(0xCC),
    @(0xDD),
    @(0xEE),
    @(0xFF),

    @(0x92, 0x49, 0x24), @(0x92, 0x49, 0x24),
    @(0x49, 0x29, 0x92), @(0x49, 0x29, 0x92),
    @(0x29, 0x92, 0x49), @(0x29, 0x92, 0x49),

    @(0x6D, 0xB6, 0xDB),
    @(0xB6, 0xDB, 0x6D),
    @(0xDB, 0x6D, 0xB6)
)

function Perform-SimpleGutmann([Byte[]] $Buffer, [Byte] $Value)
{
    for (($Index = 0), ($Length = $Buffer.Count); $Index -lt $Length; ++$Index)
    {
        $Buffer[$Index] = $Value
    }
}

function Perform-PeriodicGutmann([Byte[]] $Buffer, [Byte[]] $Values)
{
    for (($Index = 0), ($Length = $Buffer.Count), ($Period = $Values.Count); $Index -lt $Length; ++$Index)
    {
        $Buffer[$Index] = $Values[$Index % $Period]
    }
}

function Perform-Randomization([Byte[]] $Buffer)
{
    $Script:RNG.GetBytes($Buffer)
}

if (-not (Test-Path -Path:$Path -Type:Leaf)) {
    Write-Host "[Error] Destroy-Item: File `"$FilePath`" is not a valid path."
    return
}

Write-Host "Begin destruction of `"$Path`". (Gutmann Method)"

$Buffer = [Byte[]]::New( (Get-ItemPropertyValue -Path:$Path -Name:Length) )

foreach ($Step in 1 .. 4)
{
    Write-Host "Lead-in randomization: $Step of 4.`r" -NoNewLine
    Perform-Randomization($Buffer)
    Set-Content -Path:$Path -Value:$Buffer -AsByteStream
}

$Step = 1
foreach ($Pattern in $Gutmann | Sort-Object { Get-Random })
{
    Write-Host "Mag pattern: $Step of 27.         `r" -NoNewLine

    if ($Pattern.Count -gt 1)
    {
        Perform-PeriodicGutmann $Buffer $Pattern
    }
    else
    {
        Perform-SimpleGutmann $Buffer $Pattern[0]
    }

    Set-Content -Path:$Path -Value:$Buffer -AsByteStream

    $Step++
}

foreach ($Step in 1 .. 4)
{
    Write-Host "Lead-out randomization: $Step of 4.`r" -NoNewLine
    Perform-Randomization($Buffer)
    Set-Content -Path:$Path -Value:$Buffer -AsByteStream
}

Write-Host "File `"$Path`" has been destroyed. Deleting."

Remove-Item -Path:$Path -Force
