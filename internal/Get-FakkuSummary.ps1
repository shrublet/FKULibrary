function Get-FakkuSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Summary = ($WebRequest -split 'description" content="(.*?)">')[1]?.Trim()`
        -replace '&(?!amp;)', '&amp;'

    Write-Output $Summary
}
