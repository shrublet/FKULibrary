function Get-FakkuTags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Tags = (($WebRequest | Select-String -Pattern '(?s)<a href="\/tags\/.*?">(.*?)<' -AllMatches).Matches |
        ForEach-Object { ($_.Groups[1].Value).Trim() }) -join ', '

    Write-Output ([Net.WebUtility]::HtmlDecode($Tags))
}
