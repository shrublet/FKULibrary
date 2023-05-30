function Get-FakkuPublisher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Publisher = ($WebRequest -split '<a href="\/publishers\/.*?>(.*?)<\/a>')[1]?.Trim()

    Write-Output ([Net.WebUtility]::HtmlDecode($Publisher))
}
