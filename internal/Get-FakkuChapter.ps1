function Get-FakkuChapter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest,

        [Parameter(Mandatory = $true)]
        [String]$Url
    )

    $Subdirectory = ($Url -split 'fakku.net')[1]
    $Chapter = ($WebRequest -split "((?s)<a href=`"$Subdirectory`")")

    # Check if URL exists in body and slices there
    if ($Chapter[1]) { $ChapterDiv = $Chapter[0] }

    # This retrieves numbers from books and returns as a range (e.g. 1-10)
    # The RegEx is a bit inflexible and may be prone to breakage
    elseif ($WebRequest -match '(?s)>Chapters<\/h2>') {
        $ChapterDiv = ($WebRequest -split '(?s)>Chapters<\/h2>(.*?)>Hentai related to')[1]
        $Number = '1-'
    }

    # Retrieves last number found
    if ($ChapterDiv) {
        $Number += ($ChapterDiv -split '(?s)<div class=".*?">(\d+)<\/div>')[-2]?.Trim()
    }

    Write-Output $Number
}
