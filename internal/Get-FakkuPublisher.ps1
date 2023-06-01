function Get-FakkuPublisher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Publisher = ($WebRequest -split '(?s)<a href="\/publishers\/.*?>(.*?)<\/a>')[1]?.Trim()
    $Publisher = [Net.WebUtility]::HtmlDecode($Publisher)

    Write-Output $Publisher
}
