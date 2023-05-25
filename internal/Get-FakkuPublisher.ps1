function Get-FakkuPublisher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Publisher = ($WebRequest -split '<a href="\/publishers\/.*?>(.*?)<\/a>')[1]?.Trim()`
        -replace '&(?!amp;)', '&amp;'

    Write-Output $Publisher
}
