function Get-FakkuLinks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Path')]
        [IO.FileInfo]$FilePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Path')]
        [Switch]$Recurse,

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Name')]
        [String]$Name
    )

    begin {
        if ($FilePath) {
            $Archives = Get-LocalArchives -FilePath $FilePath -Recurse:$Recurse
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Name' {
                [PSCustomObject]@{
                    FAKKU = ConvertTo-FakkuUrl -Name $Name
                }
            }

            'Path' {
                foreach ($File in $Archives) {
                    [PSCustomObject]@{
                        FAKKU = ConvertTo-FakkuUrl -Name $File.BaseName
                    }
                }
            }
        }
    }

}
