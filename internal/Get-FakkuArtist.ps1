function Get-FakkuArtist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    # Div taken out to avoid grabbing artists from elswhere on the page
    $ArtistDiv = ($WebRequest -split '(?s)<div.*?>Artist<\/div>(.*?)<\/div>')[1]
    $Artist = (($ArtistDiv | Select-String -Pattern '(?s)<a href="\/artists\/.*?>(.*?)<\/a>' -AllMatches).Matches |
        ForEach-Object { ($_.Groups[1].Value).Trim() }) -join ', '
    $Artist = [Net.WebUtility]::HtmlDecode($Artist)

    Write-Output $Artist
}
