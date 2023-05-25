function Get-FakkuGenres {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Genres = (($WebRequest | Select-String -Pattern '<a href="\/tags\/.*?">(.*?)<' -AllMatches).Matches |
        ForEach-Object { ($_.Groups[1].Value).Trim() }) -join ", "

    Write-Output $Genres
}
