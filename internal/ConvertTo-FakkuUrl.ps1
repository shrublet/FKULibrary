function ConvertTo-FakkuUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    $UrlName = $Name.ToLower()`
        -replace '★', 'bzb' `
        -replace '☆', 'byb' `
        -replace '♪', 'bvb' `
        -replace '↑', 'bb' `
        -replace '×', 'x' `
        -replace '\s+', ' '
        # -replace "'", 'bgb'

    if ($UrlName -match '^(?:\[.+?\])*(.+)\(.+?\)(?:\s*\[.+?\])*\.[a-z0-9]+$') {
        $UrlName = $Matches[1].Trim()
    }

    $UrlName = ($UrlName -replace '[^-a-z0-9\s]+', '' -replace '\s', '-' -replace '-+', '-').Trim('-')
    $FakkuUrl = "https://www.fakku.net/hentai/$UrlName-english"

    Write-Output $FakkuUrl
}
