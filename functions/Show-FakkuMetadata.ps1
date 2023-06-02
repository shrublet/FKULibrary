function Show-FakkuMetadata {
    [CmdletBinding(DefaultParameterSetName = 'Url')]
    param(
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Name')]
        [String]$Name,

        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Url')]
        [String]$Url,

        [Parameter(Mandatory = $false, ParameterSetName = 'Url')]
        [Switch]$Safe,

        [Parameter(Mandatory = $false, ParameterSetName = 'Url')]
        [Switch]$Headless,

        [Parameter(Mandatory = $false, ParameterSetName = 'Url')]
        [Switch]$Incognito
    )

    $DriverPath = (Get-Item $PSScriptRoot).Parent
    $ProfilePath = (Join-Path -Path (Get-Item $PSScriptRoot).Parent -ChildPath 'profiles')

    Switch ($PSCmdlet.ParameterSetName) {
        'Name' {
            # Name search will not fallback on Selenium mostly just because it's kind of clunky
            try {
                $FakkuUrl = ConvertTo-FakkuUrl -Name $Name
                Write-Debug "URL: $FakkuUrl"
                $WebRequest = (Invoke-WebRequest -Uri $FakkuUrl -Method Get -Verbose:$false).Content
                $Xml = Get-MetadataXml -WebRequest $WebRequest -URL $FakkuUrl -Provider 'fakku'
            }

            # Panda name fallback
            catch {
                try {
                    Write-Debug 'Falling back on Panda.'

                    $PandaUrl = Get-PandaURL -Name $Name
                    Write-Debug "URL: $PandaUrl"
                    $WebRequest = (Invoke-WebRequest -Uri $PandaUrl -Method Get -Verbose:$false).Content
                    $Xml = Get-MetadataXml -WebRequest $WebRequest -URL $PandaUrl -Provider 'panda'
                } catch {
                    Write-Warning "Work `"$Name`" not found."
                    return
                }
            }

            Write-Output $Xml
        }

        'Url' {
            try {
                Switch -Regex ($Url) {
                    'fakku.net' {
                        $Provider = 'fakku'
                    }

                    'panda.chaika.moe' {
                        $Provider = 'panda'
                    }

                    Default {
                        Write-Warning "URL `"$Url`" is not a valid FAKKU or Panda URL."
                        return
                    }
                }

                Write-Debug "UriLocation: $Provider"
                Write-Debug "URL: $Url"

                $WebRequest = (Invoke-WebRequest -Uri $Url -Method Get -Verbose:$false).Content
                if ($Safe -and (Get-FakkuChapter -WebRequest $WebRequest -Url $NewUrl)) { throw }
                $Xml = Get-MetadataXml -WebRequest $WebRequest -URL $Url -Provider $Provider
            } catch {
                try {
                    Write-Debug 'Falling back on WebDriver.'

                    $DriverArgs = @{
                        DriverPath = $DriverPath
                        ProfilePath = $ProfilePath
                        Headless = $Headless
                        Incognito = $Incognito
                    }
                    $DriverObject = New-WebDriver @DriverArgs
                    $BrowserProfile = $DriverObject.Args.Arguments[0].Split('user-data-dir=')[1]
                    $WebDriver = New-Object $DriverObject.Driver -ArgumentList $DriverObject.Args

                    if ($Headless -and -not (Test-Path -Path $BrowserProfile\*)) {
                        $WebDriver.Navigate().GoToURL('https://fakku.net/login')
                        Write-Host 'Please log into FAKKU then press ENTER to continue...'
                        do {
                            $KeyPressed = ([Console]::ReadKey($true))
                            Start-Sleep -Milliseconds 50
                        } while ($KeyPressed.Key -ne 'enter')
                    }

                    $WebDriver.Navigate().GoToURL($Url)
                    $WebRequest = $WebDriver.PageSource
                    $Xml = Get-MetadataXML -WebRequest $WebRequest -Url $Url -Provider 'fakku'
                }
                catch {
                    Write-Warning "Error occurred while scraping `"$Url`": $PSItem"
                }
            }

            if ($WebDriver) { $WebDriver.Quit() }
            Write-Output $Xml
        }
    }
}
