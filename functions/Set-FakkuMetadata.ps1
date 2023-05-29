function Set-FakkuMetadata {
    [CmdletBinding(DefaultParameterSetName = 'File')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'File')]
        [System.IO.FileInfo]$FilePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'File')]
        [Switch]$Recurse,

        [Parameter(Mandatory = $false, ParameterSetName = 'File')]
        [String]$Url,

        [Parameter(Mandatory = $false)]
        [Int32]$Sleep,

        [Parameter(Mandatory = $false)]
        [System.IO.FileInfo]$UrlFile,

        [Parameter(Mandatory = $true, ParameterSetName = 'Batch')]
        [System.IO.FileInfo]$InputFile,

        [Parameter(Mandatory = $false)]
        [System.IO.DirectoryInfo]$DriverPath = (Get-Item $PSScriptRoot).Parent,

        [Parameter(Mandatory = $false)]
        [System.IO.DirectoryInfo]$ProfilePath = (Join-Path -Path (Get-Item $PSScriptRoot).Parent -ChildPath "profiles"),

        [Parameter(Mandatory = $false)]
        [Switch]$Headless,

        [Parameter(Mandatory = $false)]
        [Switch]$Incognito,

        [Parameter(Mandatory = $false)]
        [Switch]$Log,

        [Parameter(Mandatory = $false)]
        [System.IO.FileInfo]$LogPath = (Join-Path -Path (Get-Item $PSScriptRoot).Parent - ChildPath "fakku_library.log")
    )

    function Write-FakkuLog {
        param(
            [Switch]$Log,
            [System.IO.FileInfo]$LogPath,
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
            if ((Get-Item -LiteralPath $FilePath) -is [System.IO.DirectoryInfo]) {
                $Archive = Get-LocalArchives -FilePath $FilePath -Recurse:$Recurse
            } else {
                $Archive = @(Get-Item -LiteralPath $FilePath)
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
            $Archive = Get-Content -Path $InputFile |
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
        $Links = Get-Content -Path $UrlFile |
            ForEach-Object {$_.Trim()} |
            Where-Object { ($_ | Select-String "fakku", "panda.chaika") }
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

        # Attempt with Invoke-WebRequest and match URL
        try {
            $WebRequest = (Invoke-WebRequest -Uri $NewUrl -Method Get -Verbose:$false).Content
            $Xml = Get-MetadataXML -WebRequest $WebRequest -Url $NewUrl -Provider $UriLocation
            Set-MetadataXML -FilePath $File.FullName -XmlPath $XmlPath -Content $Xml
        }

        # WebDriver fallback
        catch {
            try {
                $DriverArgs = @{
                    DriverPath = $DriverPath
                    ProfilePath = $ProfilePath
                    Headless = $Headless
                    Incognito = $Incognito
                }
                $DriverObject = New-WebDriver @DriverArgs
                # Initialize new WebDriver if can't find one
                if (-Not $DriverObject.Args.IsRunning) {
                    $WebDriver = New-Object $DriverObject.Driver -ArgumentList $DriverObject.Args
                    # Skips login process if in headless mode or browser profile is found
                    if ($Headless -or -Not (Test-Path -Path $ProfilePath\*)) {
                        $WebDriver.Navigate().GoToURL("https://fakku.net/login")
                        Write-Host "Please log into FAKKU then press ENTER to continue..."
                        # This waits for any key rather than a specific key
                        # $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown") | Out-Null
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
                    Write-Warning "Error occurred while scraping $NewUrl : $PSItem"
                }
            }
        }
        Write-FakkuLog -Log:$Log -LogPath $LogPath -Source $UriLocation
        Write-Verbose "Set $FilePath with $NewUrl."
        Write-Debug "Set $File using $UriLocation."
    }
    if ($WebDriver) {$WebDriver.Quit()}
    Write-Host "Complete."
}
