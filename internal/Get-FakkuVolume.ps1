function Get-FakkuVolume {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest,

        [Parameter(Mandatory = $true)]
        [String]$Url
    )

    $Path = ($Url -split 'fakku.net')[1]
    $Volume = ($WebRequest -split "(<a href=`"$Path`")")
    # Check if link to URL exists in body
    if ($Volume[1]) {
        $Number = ($Volume[0] -split '<div class=".*?">(\d+)<\/div>')[-2]?.Trim()
    }

    Write-Output $Number
}
