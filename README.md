# F! Library

Scrape metadata from [FAKKU](https://www.fakku.net/) or [Panda](https://panda.chaika.moe/) and build your own local FAKKU library with Komga or any other CMS that supports `ComicInfo.xml` metadata.

<details>

  <summary>Example results</summary>

  ```xml
  <ComicInfo xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <Title>Sekigahara-san Has Something to Hide</Title>
    <Series>Sekigahara-san Has Something to Hide</Series>
    <Number>1</Number>
    <Summary>Thrilling and agonizing! The start of a rich girl series!</Summary>
    <Year>2020</Year>
    <Month>01</Month>
    <Writer>Tsukako</Writer>
    <Publisher>FAKKU</Publisher>
    <Tags>Bunny Girl, Busty, Cosplay, Deepthroat, Fishnets, Hentai, Light Hair, No Sex, Ojousama, Paizuri, Stockings, Story Arc, Uncensored</Tags>
    <Genre>Original Work</Genre>
    <Web>https://www.fakku.net/hentai/sekigahara-san-has-something-to-hide-english</Web>
    <LanguageISO>en</LanguageISO>
    <Manga>Yes</Manga>
    <SeriesGroup>Comic Kairakuten BEAST 2020-01</SeriesGroup>
    <AgeRating>Adults Only 18+</AgeRating>
  </ComicInfo>
  ```
![Image of the series "Sekigahara-san Has Something to Hide" in Komga.](/docs/images/komga.jpg)

</details>

#### Quick links

- [Getting Started](#getting-started)
- [Setup](#setup)
- [Usage](#usage)
- [Examples](#examples)
- [Parameters](#parameter-descriptions)

<br/><br/>

## Getting Started

#### Prerequisites

- [PowerShell 5.0 or higher (6.0+ recommended)](https://aka.ms/powershell-release?tag=stable)
- Komga or any other CMS that supports `ComicInfo.xml` metadata

#### Accepted archive filenames examples

- `[Circle (Artist)] Title (Comic XXX) [Publisher] [etc.].ext`
- `[Artist] Title (Comic XXX).ext`
- `Title (Comic XXX).ext`
- `Title.ext`

#### Supported filetypes
- `.zip`
- `.cbz`
- `.rar`
- `.cbr`
- `.7z`
- `.cb7`

<br/><br/>

## Setup

#### Clone the repository

- Clone the repository by [downloading](https://github.com/shrublet/FKULibrary/archive/refs/heads/main.zip) and extracting the files to a directory of your choice or with Git.

```sh
git clone https://github.com/shrublet/FKULibrary.git
```

#### Setup Selenium WebDriver (optional)

- It's highly recommneded to setup and download Selenium as well to access publicly blocked pages. Download the WebDriver for your browser and the Selenium for C# package (linked below). Extract the WebDriver executable (for Google Chrome, this would be `chromedriver.exe`) and `WebDriver.dll` from the raw `.nupkg` package to the root of your extracted repository (i.e. `.\fakku-meta-scraper-main`).
  - <sub>[Browser WebDriver executables](https://www.selenium.dev/documentation/webdriver/troubleshooting/errors/driver_location/#download-the-driver)</sub>
  - <sub>[Selenium WebDriver for C#](https://www.nuget.org/api/v2/package/Selenium.WebDriver)</sub>
> [!TIP]
> <sub>The `WebDriver.dll` is packaged inside the `.nupkg` file under `.\lib\net48\` and can be opened via any file archiver. Most Windows PCs should have .NET 4.8, so this is the recommended library. If the WebDriver isn't working as expected, ensure the version matches with your browser or try updating your browser/downgrading the WebDriver.</sub>

#### Import the module

- You will need to do this every time you close your PowerShell window unless you add the module to your PowerShell module PATH. Ensure that your PowerShell window is opened in the correct directory.

```sh
cd "C:\path\to\extracted\repository"
```

```sh
Import-Module .\Fakku-Library.psm1
```

<br/><br/>

## Usage

#### Set metadata for archive(s)

```sh
Set-FakkuMetadata
```

###### Available parameters

[`-FilePath`](#-filepath)
[`-Recurse`](#-recurse)
[`-Url`](#-url)
[`-UrlFile`](#-urlfile)
[`-InputFile`](#-inputfile)
[`-Sleep`](#-sleep)
[`-Destination`](#-destination)
[`-Safe`](#-safe)
[`-Headless`](#-headless)
[`-Incognito`](#-incognito)
[`-Log`](#-log)
[`-LogPath`](#-logpath)

#### Retrieve and write metadata to the console

```sh
Show-FakkuMetadata
```

###### Available parameters

[`-Name`](#-name)
[`-Url`](#-url)
[`-Safe`](#-safe)
[`-Headless`](#-headless)
[`-Incognito`](#-incognito)

#### Return corresponding FAKKU links for archive(s)

```sh
Get-FakkuLinks
```

###### Available parameters

[`-FilePath`](#-filepath)
[`-Name`](#-name)
[`-Recurse`](#-recurse)

<br/><br/>

## Examples

#### Set metadata for an archive

```sh
Set-FakkuMetadata -FilePath "C:\path\to\file.zip"
```

#### Set metadata for archives in specified directory

```sh
Set-FakkuMetadata -FilePath "C:\path\to\files"
```

#### Set metadata for an archive from a FAKKU link

```sh
Set-FakkuMetadata "C:\path\to\file.zip" -Url "https://www.fakku.net/hentai/Bare-Girl-english"
```

#### Set metadata for a list of archives

```sh
Set-FakkuMetadata -InputFile "C:\path\to\list\of\archives.txt"
```

#### Set metadata for archives in specified directory with a list of URLs

```sh
Set-FakkuMetadata "C:\path\to\files" -UrlFile "C:\path\to\list\of\urls.txt"
```

#### Get and display metadata from a FAKKU link

```sh
Show-FakkuMetadata https://www.fakku.net/hentai/Bare-Girl-english
```

#### Get and display metadata from a title

```sh
Show-FakkuMetadata "Bare Girl"
```


<br/><br/>

## Parameter Descriptions

##### `-FilePath`
> <sub>Archive or directory or archives to set metadata for</sub>

##### `-Name`
> <sub>Work title to search FAKKU/Panda for</sub>

##### `-Recurse`
> <sub>Whether to recursively search the directory for archives (default: `False`)</sub>

##### `-Url`
> <sub>FAKKU/Panda URL to pull metadata from</sub>

##### `-Sleep`
> <sub>Time to sleep between scrapes (default: `0`)</sub>

##### `-InputFile`
> <sub>Text file with directories to tag</sub>

##### `-UrlFile`
> <sub>Text file with FAKKU/Panda URLs to use for tagging (compatible with both `-FilePath` and `-InputFile`)</sub>

##### `-Destination`
> <sub>Path to move completed archives to (default: `None`)</sub>

##### `-Safe`
> <sub>Force the use of Selenium to scrape metadata to avoid edge-case metadata issues (default: `False`)</sub>

##### `-Headless`
> <sub>Launches browser in headless mode (default: `True`)</sub>

##### `-Incognito`
> <sub>Launches browser in incognito/private mode (default: `False`)</sub>

##### `-Log`
> <sub>If logs should be written (default: `False`)</sub>

##### `-LogPath`
> <sub>Path to save log to (default: `.\fakku_library.log`)</sub>
