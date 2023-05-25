function Get-FakkuGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Group = ($WebRequest -split '<a href="\/magazines\/.*?>(.*?)<\/a>')[1]?.Trim()
    if (-Not $Group) {
        $Group = ($WebRequest -split '<a href="\/events\/.*?>(.*?)<\/a>')[1]?.Trim()
    }

    Write-Output ($Group -replace '&(?!amp;)', '&amp;')
}
