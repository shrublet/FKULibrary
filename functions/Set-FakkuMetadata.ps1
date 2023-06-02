function Set-FakkuMetadata {
    [CmdletBinding(DefaultParameterSetName = 'File')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'File')]
        [IO.FileInfo]$FilePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'File')]
        [Switch]$Recurse,

        [Parameter(Mandatory = $false, ParameterSetName = 'File')]
        [String]$Url,

        [Parameter(Mandatory = $false)]
        [Int32]$Sleep,

        [Parameter(Mandatory = $true, ParameterSetName = 'Batch')]
        [IO.FileInfo]$InputFile,

        [Parameter(Mandatory = $false)]
        [IO.FileInfo]$UrlFile,

        [Parameter(Mandatory = $false)]
        [IO.DirectoryInfo]$Destination,

        [Parameter(Mandatory = $false)]
        [Switch]$Safe,

        [Parameter(Mandatory = $false)]
        [Switch]$Headless,

        [Parameter(Mandatory = $false)]
        [Switch]$Incognito,

        [Parameter(Mandatory = $false)]
        [Switch]$Log,

        [Parameter(Mandatory = $false)]
        [IO.FileInfo]$LogPath = (Join-Path -Path (Get-Item $PSScriptRoot).Parent - ChildPath 'fakku_library.log')
    )

    function Write-FakkuLog {
        param(
            [Switch]$Log,
            [IO.FileInfo]$LogPath,
            [String]$Source
        )

        if ($Log) {
            [PSCustomObject]@{
                FilePath = $FilePath
                Url      = $FakkuUrl
                Source   = $Source
            } | Export-Csv -Path $LogPath -Append
        }
    }

    $ProgressPreference = 'SilentlyContinue'
    $DriverPath = (Get-Item $PSScriptRoot).Parent
    $ProfilePath = (Join-Path -Path (Get-Item $PSScriptRoot).Parent -ChildPath 'profiles')

    Switch ($PSCmdlet.ParameterSetName) {
        'File' {
            # Check if FilePath is a directory or file to determine how to proceed
            if ((Get-Item -LiteralPath $FilePath) -is [IO.DirectoryInfo]) {
                [array]$Archive = Get-LocalArchives -FilePath $FilePath -Recurse:$Recurse
            } else {
                [array]$Archive = Get-Item -LiteralPath $FilePath
            }

            # URL validation
            if ($PSBoundParameters.ContainsKey('Url')) {
                if (Test-Path -Path $FilePath -PathType Container) {
                    Write-Warning 'URL parameter can only be used with an archive, not a directory.'
                    return
                }
                # A little more flexible if future providers added
                elseif (-not ($Url | Select-String 'fakku.net', 'panda.chaika.moe')) {
                    Write-Warning "URL `"$Url`" is not a valid FAKKU or Panda URL."
                    return
                }
            }
        }

        'Batch' {
            [array]$Archive = Get-Content -Path $InputFile |
                Where-Object { Test-Path -Path $_.trim().trim('"') } |
                ForEach-Object { Get-Item -Path $_.trim().trim('"') }
        }
    }

    if ($PSBoundParameters.ContainsKey('UrlFile')) {
        if ($Url) {
            Write-Warning 'URL parameter is not compatible with batch tagging.'
            return
        }

        # URL validation
        [array]$Links = Get-Content -Path $UrlFile |
            ForEach-Object { $_.Trim() } |
            Where-Object { ($_ | Select-String 'fakku.net', 'panda.chaika.moe') }
        if ($Links.Count -ne $Archive.Count) {
            Write-Warning 'File count does not match URL count.'
            return
        }
    }

    # Main loop
    foreach ($File in $Archive) {
        # Re-initializes variables for next loop
        $NewUrl = $UriLocation = $Xml = $Series = $null
        $Index = $Archive.IndexOf($File)
        $TotalIndex = $Archive.Count
        $WorkName = $File.BaseName
        $XmlPath = Join-Path -Path $File.DirectoryName -ChildPath 'ComicInfo.xml'

        Write-Host "[$($Index + 1) of $TotalIndex] Setting metadata for `"$WorkName`""
        Start-Sleep -Seconds $Sleep

        if ($Links) {
            $Link = $Links[$Index]
        } else {
            $Link = $Url
        }

        Switch -Regex ($Link) {
            'fakku.net' {
                $UriLocation = 'fakku'
                $NewUrl = $Link
            }

            'panda.chaika.moe' {
                $UriLocation = 'panda'
                $NewUrl = $Link
            }

            Default {
                $UriLocation = 'fakku'
                $NewUrl = ConvertTo-FakkuUrl -Name $WorkName
            }
        }

        Write-Debug "UriLocation: $UriLocation"
        Write-Debug "URL: $NewUrl"
        Write-Debug "Path: $File"

        # Attempt with Invoke-WebRequest and match URL
        try {
            # NOTE:
            # There's a "bug" that will erroneously label chapter number if chapters in a series are publicly obscured.
            # The only way I can think of to avoid this is to force requesting through Selenium if a series is found.
            # I've decided to not throw an error by default and implement the parameter "Safe" instead which will force
            # the use of Selenium.
            $WebRequest = (Invoke-WebRequest -Uri $NewUrl -Method Get -Verbose:$false).Content
            if ($Safe -and (Get-FakkuChapter -WebRequest $WebRequest -Url $NewUrl)) { throw }
            $Xml = Get-MetadataXML -WebRequest $WebRequest -Url $NewUrl -Provider $UriLocation
            Set-MetadataXML -FilePath $File.FullName -XmlPath $XmlPath -Content $Xml
        }

        # WebDriver fallback
        catch {
            try {
                Write-Debug 'Falling back on WebDriver...'

                # Initialize new driver instance if can't find one
                if (-not $DriverObject.Args.IsRunning) {
                    Write-Debug 'Creating new driver instance.'

                    $DriverArgs = @{
                        DriverPath = $DriverPath
                        ProfilePath = $ProfilePath
                        Headless = $Headless
                        Incognito = $Incognito
                    }
                    $DriverObject = New-WebDriver @DriverArgs
                    $BrowserProfile = $DriverObject.Args.Arguments[0].Split('user-data-dir=')[1]
                    $WebDriver = New-Object $DriverObject.Driver -ArgumentList $DriverObject.Args

                    # Skips login process if in headless mode or browser profile is found
                    if ($Headless -and -not (Test-Path -Path $BrowserProfile\*)) {
                        $WebDriver.Navigate().GoToURL('https://fakku.net/login')
                        Write-Host 'Please log into FAKKU then press ENTER to continue...'
                        do {
                            $KeyPressed = ([Console]::ReadKey($true))
                            Start-Sleep -Milliseconds 50
                        } while ($KeyPressed.Key -ne 'enter')
                    }
                }

                $WebDriver.Navigate().GoToURL($NewUrl)
                $WebRequest = $WebDriver.PageSource
                $Xml = Get-MetadataXML -WebRequest $WebRequest -Url $NewUrl -Provider $UriLocation
                Set-MetadataXML -FilePath $File.FullName -XmlPath $XmlPath -Content $Xml
            }

            # Panda URL from name fallback
            catch {
                try {
                    Write-Debug 'Falling back on Panda...'

                    $UriLocation = 'panda'
                    $NewUrl = Get-PandaURL -Name $WorkName
                    Write-Debug "URL: $NewUrl"

                    $WebRequest = (Invoke-WebRequest -Uri $NewUrl -Method Get -Verbose:$false).Content
                    $Xml = Get-MetadataXML -WebRequest $WebRequest -Url $NewUrl -Provider $UriLocation
                    Set-MetadataXML -FilePath $File.FullName -XmlPath $XmlPath -Content $Xml
                } catch {
                    Write-Warning "Error occurred while scraping `"$NewUrl`": $PSItem"
                }
            }
        }

        Write-FakkuLog -Log:$Log -LogPath $LogPath -Source $UriLocation
        Write-Verbose "Set $FilePath with $NewUrl."
        Write-Debug "Set using $UriLocation."

        # Move archive to "Destination/Artist/Series/Archive.ext".
        if ($Destination) {
            try {
                Write-Debug 'Moving archive...'

                # Remove reserved characters
                $Title = (Get-FakkuTitle -WebRequest $WebRequest)`
                    -replace '\\|\/|\||:|\*|\?|"|<|>', ''
                $Series = (Get-HtmlElement -WebRequest $WebRequest -Name 'collections')`
                    -replace '\\|\/|\||:|\*|\?|"|<|>', ''
                $Artist = ($Artist = Get-MultipleElements -WebRequest ($WebRequest -split '(?s)<div.*?>Artist<\/div>(.*?)<\/div>')[1] -Name 'artists').Split(',')[0]
                if (-not $Series) { $Series = $Title }
                $SeriesPath = Join-Path -Path $Destination -ChildPath $Artist -AdditionalChildPath $Series.TrimEnd('.')

                if (-not (Test-Path $SeriesPath)){
                    [void](New-Item -Path $SeriesPath -ItemType 'Directory')
                }

                $TargetPath = Join-Path -Path $SeriesPath -ChildPath "$Title$($File.Extension)"
                Write-Debug "Target path: $TargetPath"
                Move-Item -LiteralPath $File.FullName -Destination $TargetPath
            } catch {
                Write-Warning "Error occurred while moving `"$File`": $PSItem"
            }
        }
    }

    if ($WebDriver) { $WebDriver.Quit() }
    Write-Host 'Complete.'
}
