function Get-HtmlElement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest,

        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    # Used for the following -
    # Circle
    # Magazine/Event
    # Publisher
    # Series/Collection
    $Value = ($WebRequest -split "(?s)<a href=`"\/$Name\/.*?>(.*?)<\/a>")[1]?.Trim()
    $Value = [Net.WebUtility]::HtmlDecode($Value)

    Write-Output $Value
}

function Get-MultipleElements {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest,

        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    # Used for the following -
    # Artist
    # Tags
    # Parody
    $Values = (($WebRequest | Select-String -Pattern "(?s)<a href=`"\/$Name\/.*?>(.*?)<\/a>" -AllMatches).Matches |
        ForEach-Object { ($_.Groups[1].Value).Trim() }) -join ', '
    $Values = [Net.WebUtility]::HtmlDecode($Values)

    Write-Output $Values
}

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

function Get-FakkuSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Summary = ((($WebRequest -split '(?s)"og:description" content="(.*?)">')[1]`
        -split '(?s)Paperback ships|Paperback Release|Chapters will|Downloads will')[0]`
        -split '(?s)This content is no longer available for purchase.')?.Trim()
    $Summary = [Net.WebUtility]::HtmlDecode($Summary)

    Write-Output $Summary
}

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
