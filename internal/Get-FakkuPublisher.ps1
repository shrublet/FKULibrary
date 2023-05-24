function Get-FakkuPublisher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Publisher = ((($WebRequest -split '<a href="\/publishers\/.*?>')[1]) -split '<\/a>')[0].Trim()

    Write-Output $Publisher
}
