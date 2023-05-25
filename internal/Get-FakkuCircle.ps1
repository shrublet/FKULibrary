function Get-FakkuCircle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Circle = ($WebRequest -split '<a href="\/circles\/.*?>(.*?)<\/a>')[1]?.Trim()`
        -replace '&(?!amp;)', '&amp;'

    Write-Output $Circle
}
