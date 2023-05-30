function Get-FakkuArtist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    # Div taken out to avoid grabbing artists from elswhere on the page
    $ArtistDiv = ($WebRequest -split '<div.*?>[Aa]rtist<\/div>(.*?)<\/div>')[1]
    $Artist = (($ArtistDiv | Select-String -Pattern '<a href="\/artists\/.*?>(.*?)<' -AllMatches).Matches |
        ForEach-Object { ($_.Groups[1].Value).Trim() }) -join ", "

    Write-Output ([Net.WebUtility]::HtmlDecode($Artist))
}
