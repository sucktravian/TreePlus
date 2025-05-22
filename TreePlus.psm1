function Show-Tree {
    <#
.SYNOPSIS
    Displays a tree-like structure of folders and optionally files.

.DESCRIPTION
    Recursively lists folder structures using ASCII-style connectors, with optional emojis, file filters,
    extension-based color themes, and support for clipboard or Markdown output.

.PARAMETER Path
    The root path to start displaying the tree.

.PARAMETER Depth
    Maximum tree depth to display. Default is unlimited.

.PARAMETER ShowFiles
    Include files in the output tree.

.PARAMETER IncludeExtensions
    Only include files with these extensions (e.g. ".ps1", ".txt").

.PARAMETER ExcludeFolders
    Folder names to exclude from output.

.PARAMETER IncludeHidden
    Include hidden files and folders.

.PARAMETER ToClipboard
    Copy tree output to clipboard.

.PARAMETER DarkTheme
    Use colors optimized for dark terminals.

.PARAMETER OutputFile
    Path to save the output (plain or markdown depending on -MarkdownOutput).

.PARAMETER PlainAscii
    Disable emojis and display tree using plain ASCII.

.PARAMETER MarkdownOutput
    Format the output as a markdown list (suitable for GitHub).

.PARAMETER ShowFileSizes
    Display file sizes next to file names (except in Markdown mode).

.PARAMETER Favorite
    Name of a preset configuration with commonly used parameter combinations.
#>

    [CmdletBinding()]
    [Alias("tree", "lstree")]
    param (
        [Parameter(Position = 0)]
        [string]$Path = ".",

        [int]$Depth = [int]::MaxValue,

        [switch]$ShowFiles,

        [string[]]$IncludeExtensions = @(),

        [string[]]$ExcludeFolders = @(),

        [switch]$IncludeHidden,

        [switch]$ToClipboard,

        [switch]$DarkTheme,

        [string]$OutputFile,

        [switch]$PlainAscii,

        [switch]$MarkdownOutput,

        [switch]$ShowFileSizes,

        [string]$Favorite
    )

    # Favorite profiles
    $Favorites = @{
        "markdown-dev" = @{
            ShowFiles      = $true
            MarkdownOutput = $true
            ShowFileSizes  = $true
            Depth          = 5
            OutputFile     = "tree.md"
        }
        "clipboard-dark" = @{
            ShowFiles   = $true
            ToClipboard = $true
            DarkTheme   = $true
            PlainAscii  = $true
        }
    }

    if ($Favorite) {
        if ($Favorites.ContainsKey($Favorite)) {
            $preset = $Favorites[$Favorite]
            foreach ($key in $preset.Keys) {
                if (-not $PSBoundParameters.ContainsKey($key)) {
                    Set-Variable -Name $key -Value $preset[$key] -Scope Local
                }
            }
        }
        else {
            Write-Warning "Unknown favorite '$Favorite'. Available: $($Favorites.Keys -join ', ')"
        }
    }

    if (-not (Test-Path $Path)) {
        Write-Error "The specified path '$Path' does not exist."
        return
    }

    $global:OutputLines = @()
    $useEmojis = -not $PlainAscii -and -not $MarkdownOutput

    $emojiFolder = "`u{1F4C1}"  # 📁
    $emojiFile = "`u{1F4C4}"    # 📄

    $folderColor = if ($DarkTheme) { "Yellow" } else { "DarkYellow" }
    $defaultFileColor = if ($DarkTheme) { "Cyan" } else { "DarkCyan" }

    $fileColorMap = @{
        '.ps1'  = 'Green'
        '.txt'  = 'Gray'
        '.json' = 'Magenta'
        '.csv'  = 'White'
        '.log'  = 'DarkGray'
        '.xml'  = 'DarkCyan'
        '.md'   = 'Cyan'
    }

    if (-not $MarkdownOutput -and -not $PlainAscii) {
        Write-Host "Legend: " -NoNewline
        Write-Host " Folders" -ForegroundColor $folderColor -NoNewline
        Write-Host ", " -NoNewline
        Write-Host " Files" -ForegroundColor $defaultFileColor
    }

    function Get-Tree {
        param (
            [string]$BasePath,
            [string]$Indent = "",
            [int]$Level = 0
        )

        if ($Level -ge $Depth) { return }

        Write-Progress -Activity "Building Tree" -Status "Scanning $BasePath" -PercentComplete (($Level / $Depth) * 100)

        $items = Get-ChildItem -Path $BasePath -Force | Sort-Object -Property PSIsContainer, Name
        $count = $items.Count

        for ($i = 0; $i -lt $count; $i++) {
            $item = $items[$i]
            $isLast = ($i -eq $count - 1)

            if (-not $IncludeHidden -and $item.Attributes -match "Hidden") {
                continue
            }

            $connector = if ($MarkdownOutput) {
                "- "
            }
            elseif ($isLast) {
                "+--"
            }
            else {
                "|--"
            }

            $newIndent = if ($MarkdownOutput) {
                $Indent + "  "
            }
            elseif ($isLast) {
                $Indent + "    "
            }
            else {
                $Indent + "|   "
            }

            if ($item.PSIsContainer) {
                if ($ExcludeFolders -contains $item.Name) { continue }

                $emoji = if ($useEmojis) { "$emojiFolder " } else { "" }

                $line = "$Indent$connector$emoji$($item.Name)"
                $global:OutputLines += $line
                if (-not $MarkdownOutput) {
                    Write-Host $line -ForegroundColor $folderColor
                }

                Get-Tree -BasePath $item.FullName -Indent $newIndent -Level ($Level + 1)
            }
            elseif ($ShowFiles) {
                if ($IncludeExtensions.Count -gt 0 -and ($IncludeExtensions -notcontains $item.Extension)) {
                    continue
                }

                $emoji = if ($useEmojis) { "$emojiFile " } else { "" }

                $size = [math]::Round($item.Length / 1024, 1)
                $ext = $item.Extension.ToLower()
                $color = $fileColorMap[$ext]
                if (-not $color) { $color = $defaultFileColor }

                $sizeText = if ($ShowFileSizes -and -not $MarkdownOutput) {
                    " [$size KB]"
                }
                else {
                    ""
                }

                $line = "$Indent$connector$emoji$($item.Name)$sizeText"
                $global:OutputLines += $line
                if (-not $MarkdownOutput) {
                    Write-Host $line -ForegroundColor $color
                }
            }
        }
    }

    $global:OutputLines = @()
    if ($MarkdownOutput) {
        $header = "# Directory Tree: $Path"
        $global:OutputLines += $header
    }
    else {
        Write-Host $Path -ForegroundColor Green
    }

    Get-Tree -BasePath $Path

    if ($OutputFile) {
        try {
            $outPath = $OutputFile
            if ($MarkdownOutput -and (-not $OutputFile.EndsWith(".md"))) {
                $outPath = [IO.Path]::ChangeExtension($OutputFile, "md")
            }
            $global:OutputLines | Out-File -FilePath $outPath -Encoding utf8
            Write-Host "`nTree exported to '$outPath'" -ForegroundColor Green

            if (Test-Path $outPath) {
                Start-Process notepad.exe $outPath
            }
        }
        catch {
            Write-Error "Failed to write output file: $_"
        }
    }

    if ($ToClipboard) {
        try {
            $global:OutputLines -join "`r`n" | Set-Clipboard
            Write-Host "Tree copied to clipboard" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to copy to clipboard: $_"
        }
    }
}
Export-ModuleMember -Function Show-Tree