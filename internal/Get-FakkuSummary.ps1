function Get-FakkuSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Summary = ((($WebRequest -split '(?s)"og:description" content="(.*?)">')[1]`
        -split '(?s)Paperback ships|Chapters will|Downloads will')[0]`
        -split '(?s)This content is no longer available for purchase.')?.Trim()
    $Summary = [Net.WebUtility]::HtmlDecode($Summary)

    Write-Output $Summary
}
