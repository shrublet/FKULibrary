function Get-FakkuParody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    # In the rare case there's multiple Parody attributions, it will only take the first
    $Parody = ($WebRequest -split '<a href="\/series\/.*?>(.*?)<\/a>')[1]?.Trim()`
        -replace '&(?!amp;)', '&amp;'

    Write-Output $Parody
}
