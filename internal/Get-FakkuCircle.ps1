function Get-FakkuCircle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Circle = ($WebRequest -split '(?s)<a href="\/circles\/.*?>(.*?)<\/a>')[1]?.Trim()
    $Circle = [Net.WebUtility]::HtmlDecode($Circle)

    Write-Output $Circle
}
