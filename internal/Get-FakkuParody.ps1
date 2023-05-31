function Get-FakkuParody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    # Comma delimits multiple entries
    $Parody = (($WebRequest | Select-String -Pattern '(?s)<a href="\/series\/.*?">(.*?)<' -AllMatches).Matches |
        ForEach-Object { ($_.Groups[1].Value).Trim() }) -join ', '

    # Disposes additional parody entries
    # $Parody = ($WebRequest -split '(?s)<a href="\/series\/.*?>(.*?)<\/a>')[1]?.Trim()

    Write-Output ([Net.WebUtility]::HtmlDecode($Parody))
}
