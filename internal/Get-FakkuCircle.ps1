function Get-FakkuCircle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Circle = ($WebRequest -split '(?s)<a href="\/circles\/.*?>(.*?)<\/a>')[1]?.Trim()

    Write-Output ([Net.WebUtility]::HtmlDecode($Circle))
}
