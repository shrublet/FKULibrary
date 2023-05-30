function Get-FakkuTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Title = ($WebRequest -split 'title" content="(.*?)[Hh]entai by.*">')[1]?.Trim()

    Write-Output ([Net.WebUtility]::HtmlDecode($Title))
}
