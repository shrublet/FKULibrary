function Get-FakkuUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    $UrlName = $Name.ToLower()`
        -replace '★', 'bzb' `
        -replace '☆', 'byb' `
        -replace '♪', 'bvb' `
        -replace '↑', 'b' `
        -replace '×', 'x' `
        -replace '\s+', ' '

    # Matches the following -
    # [Circle (Artist)] Title (Comic XXX) [Publisher] [etc.].ext
    # [Artist] Title (Comic XXX).ext
    # Title (Comic XXX).ext
    if ($UrlName -match '^(?:\[.+?\])*(.+)\(.+?\)(?:\s*\[.+?\])*\.[a-z0-9]+$') {
        $UrlName = $Matches[1].Trim()
    }

    $UrlName = ($UrlName -replace '[^-a-z0-9\s]+', '' -replace '\s', '-' -replace '-+', '-').Trim('-')
    $FakkuUrl = "https://www.fakku.net/hentai/$UrlName-english"

    Write-Output $FakkuUrl
}
