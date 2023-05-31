function Get-FakkuTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Title = ($WebRequest -split '(?s)title" content="(.*?)Hentai by.*">')[1]?.Trim()

    Write-Output ([Net.WebUtility]::HtmlDecode($Title))
}
