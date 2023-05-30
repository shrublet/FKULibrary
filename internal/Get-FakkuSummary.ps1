function Get-FakkuSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Summary = ($WebRequest -split 'description" content="(.*?)">')[1]?.Trim()

    Write-Output ([Net.WebUtility]::HtmlDecode($Summary))
}
