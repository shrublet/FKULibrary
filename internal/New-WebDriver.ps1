function New-WebDriver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$DriverPath,

        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$ProfilePath,

        [Parameter(Mandatory = $false)]
        [bool]$Headless = $false,

        [Parameter(Mandatory = $false)]
        [Switch]$Incognito = $false
    )

    try {
        Add-Type -Path (Get-Item (Join-Path -Path $DriverPath -ChildPath 'webdriver.dll'))
        $DriverExe = Get-Item (Join-Path -Path $DriverPath -ChildPath '*driver.exe') |
            Select-Object -First 1
        $UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0'
    } catch {
        Write-Warning "Can't find WebDriver.dll or executable."
        return
    }

    Switch ($DriverExe.Name) {
        'msedgedriver.exe' {
            Write-Debug 'Using Microsoft Edge.'
            $DriverOptions = New-Object OpenQA.Selenium.Edge.EdgeOptions
            $DriverService = [OpenQA.Selenium.Edge.EdgeDriverService]::CreateDefaultService($DriverPath)
            $Driver = [OpenQA.Selenium.Edge.EdgeDriver]
            $BrowserProfile = Join-Path -Path $ProfilePath -ChildPath 'Edge'
            $DriverOptions.AddArgument("user-data-dir=$BrowserProfile")
            $DriverOptions.AddArgument("user-agent=$UserAgent")
            if (-Not $Headless) { $DriverOptions.AddArgument('headless') }
            if ($Incognito) { $DriverOptions.AddArgument('inprivate') }
        }
        'chromedriver.exe' {
            Write-Debug 'Using Google Chrome.'
            $DriverOptions = New-Object OpenQA.Selenium.Chrome.ChromeOptions
            $DriverService = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService($DriverPath)
            $Driver = [OpenQA.Selenium.Chrome.ChromeDriver]
            $BrowserProfile = Join-Path -Path $ProfilePath -ChildPath 'Chrome'
            $DriverOptions.AddArgument("user-data-dir=$BrowserProfile")
            $DriverOptions.AddArgument("user-agent=$UserAgent")
            if (-Not $Headless) { $DriverOptions.AddArgument('headless') }
            if ($Incognito) { $DriverOptions.AddArgument('incognito') }
        }
        # Untested, but I just hope it works lol.
        'geckodriver.exe' {
            Write-Debug 'Using Firefox.'
            $DriverOptions = New-Object OpenQA.Selenium.firefox.FirefoxOptions
            $DriverService = [OpenQA.Selenium.firefox.FirefoxDriverService]::CreateDefaultService($DriverPath)
            $DriverProfile = New-Object OpenQA.Selenium.firefox.FirefoxProfile
            $Driver = [OpenQA.Selenium.firefox.FirefoxDriver]
            $BrowserProfile = Join-Path -Path $ProfilePath -ChildPath 'Firefox'
            $DriverOptions.AddArgument("profile $BrowserProfile")
            $DriverProfile.SetPreference('general.useragent.override', $UserAgent)
            if (-Not $Headless) { $DriverOptions.AddArgument('headless') }
            if ($Incognito) { $DriverOptions.AddArgument('private') }
        }
        Default {
            Write-Warning "Couldn't find compatible WebDriver executable."
            return
        }
    }

    $DriverService.SuppressInitialDiagnosticInformation = $true
    $DriverService.HideCommandPromptWindow = $true
    $Arguments = @($DriverService, $DriverOptions)
    if ($DriverProfile) { $Arguments += $DriverProfile }
    $DriverObject = @{
        Driver = $Driver
        Args = $Arguments
    }
    return $DriverObject
}
