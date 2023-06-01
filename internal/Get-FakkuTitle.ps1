function Get-FakkuTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Title = ($WebRequest -split '(?s)"og:title" content="(.*?)Hentai by.*">')[1]?.Trim()
    $Title = [Net.WebUtility]::HtmlDecode($Title)

    Write-Output $Title
}
