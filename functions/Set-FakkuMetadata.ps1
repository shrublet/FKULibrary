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

        [Parameter(Mandatory = $false)]
        [IO.FileInfo]$UrlFile,

        [Parameter(Mandatory = $false)]
        [IO.DirectoryInfo]$Destination,

        [Parameter(Mandatory = $true, ParameterSetName = 'Batch')]
        [IO.FileInfo]$InputFile,

        [Parameter(Mandatory = $false)]
        [IO.DirectoryInfo]$DriverPath = (Get-Item $PSScriptRoot).Parent,

        [Parameter(Mandatory = $false)]
        [IO.DirectoryInfo]$ProfilePath = (Join-Path -Path (Get-Item $PSScriptRoot).Parent -ChildPath "profiles"),

        [Parameter(Mandatory = $false)]
        [Switch]$Headless,

        [Parameter(Mandatory = $false)]
        [Switch]$Incognito,

        [Parameter(Mandatory = $false)]
        [Switch]$Log,

        [Parameter(Mandatory = $false)]
        [IO.FileInfo]$LogPath = (Join-Path -Path (Get-Item $PSScriptRoot).Parent - ChildPath "fakku_library.log")
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
                    Write-Warning "URL parameter can only be used with an archive, not a directory."
                    return
                }

                # A little more flexible if future providers added
                elseif (-not ($String | Select-String "fakku.net", "panda.chaika.moe")) {
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
            Write-Warning "URL parameter is not compatible with batch tagging."
            return
        }

        # URL validation
        [array]$Links = Get-Content -Path $UrlFile |
            ForEach-Object {$_.Trim()} |
            Where-Object { ($_ | Select-String "fakku.net", "panda.chaika") }
        if ($Links.Count -ne $Archive.Count) {
            Write-Warning "File count does not match URL count."
            return
        }
    }

    foreach ($File in $Archive) {
        $Index = $Archive.IndexOf($File)
        $TotalIndex = $Archive.Count
        # Re-initializes variables for next loop
        $NewUrl = $UriLocation = $Xml = $null
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
                $NewUrl = Get-FakkuUrl -Name $WorkName
            }
        }

        Write-Debug "UriLocation: $UriLocation"
        Write-Debug "URL: $NewUrl"
        Write-Debug "Path: $File"

        # Attempt with Invoke-WebRequest and match URL
        try {
            $WebRequest = (Invoke-WebRequest -Uri $NewUrl -Method Get -Verbose:$false).Content
            $Xml = Get-MetadataXML -WebRequest $WebRequest -Url $NewUrl -Provider $UriLocation
            Set-MetadataXML -FilePath $File.FullName -XmlPath $XmlPath -Content $Xml
        }

        # WebDriver fallback
        catch {
            try {
                Write-Debug "Falling back on WebDriver."

                $DriverArgs = @{
                    DriverPath = $DriverPath
                    ProfilePath = $ProfilePath
                    Headless = $Headless
                    Incognito = $Incognito
                }
                $DriverObject = New-WebDriver @DriverArgs
                $BrowserProfile = $DriverObject.Args.Arguments[0].Split("user-data-dir=")[1]
                if (-not $DriverObject.Args.IsRunning) {
                    $WebDriver = New-Object $DriverObject.Driver -ArgumentList $DriverObject.Args
                    # Skips login process if in headless mode or browser profile is found
                    if ($Headless -and -not (Test-Path -Path $BrowserProfile\*)) {
                        $WebDriver.Navigate().GoToURL("https://fakku.net/login")
                        Write-Host "Please log into FAKKU then press ENTER to continue..."
                        # This waits for any key rather than a specific key
                        # [void]$Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
                        do {
                            $KeyPressed = ([Console]::ReadKey($true))
                            Start-Sleep -Milliseconds 50
                        } while ($KeyPressed.Key -ne "enter")
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
                    Write-Debug "Falling back on Panda."

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
        Write-Debug "Set $File using $UriLocation."

        # Move archive to "./Artist/Series/Archive.ext".
        if ($Destination) {
            try {
                Write-Debug "Moving archive."
                $WebRequest = $WebRequest -replace "`n|`r", ""
                # Remove reserved path characters
                $Title = (Get-FakkuTitle -WebRequest $WebRequest)`
                    -replace "\\|\/|\||:|\*|\?|\`"|<|>", ""
                $Series = (Get-FakkuSeries -WebRequest $WebRequest)`
                    -replace "\\|\/|\||:|\*|\?|\`"|<|>", ""
                $Artist = (Get-FakkuArtist -WebRequest $WebRequest).Split(",")[0]
                if ($Series) {
                    $SeriesPath = Join-Path -Path $Destination -ChildPath $Artist -AdditionalChildPath $Series
                } else {
                    $SeriesPath = Join-Path -Path $Destination -ChildPath $Artist -AdditionalChildPath $Title
                }
                if (-not (Test-Path $SeriesPath)){
                    [void](New-Item -Path $SeriesPath -ItemType "Directory")
                }
                $TargetPath = Join-Path -Path $SeriesPath -ChildPath "$Title$($File.Extension)"
                Write-Debug "Target path: $TargetPath"
                Move-Item -Path $File.FullName -Destination $TargetPath
                $Series = $null
            } catch {
                Write-Warning "Error occurred while moving `"$File`": $PSItem"
            }
        }
    }
    if ($WebDriver) {$WebDriver.Quit()}
    Write-Host "Complete."
}
