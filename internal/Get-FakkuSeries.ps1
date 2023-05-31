function Get-FakkuSeries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Series = ($WebRequest -split '(?s)<a href="\/collections\/.*?>(.*?)<\/a>')[1]?.Trim()

    Write-Output ([Net.WebUtility]::HtmlDecode($Series))
}
