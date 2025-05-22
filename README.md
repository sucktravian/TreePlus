# TreePlus

**TreePlus** is a PowerShell module that displays a tree-like structure of folders (and optionally files) with support for emojis, color-coded file types, clipboard export, and markdown output—ideal for use in documentation, terminals, or GitHub READMEs.

> 📦 Compatible with Windows PowerShell 5.1 and PowerShell 7+, but emoji support works best in PowerShell 7+ or any terminal that supports UTF-8 and Unicode emojis.

---

## ✨ Features

- ✅ Recursive folder and file listing
- 📁 Folder and 📄 file emojis (optional)
- 🎨 File extension–based color themes
- 📄 Markdown-formatted tree output for GitHub
- 📋 Clipboard export support
- 🗂️ Depth control, file filtering, hidden file visibility
- 🧪 Built-in Pester tests

---

## 🚀 Installation

Install from the PowerShell Gallery:
```powershell
Install-Module -Name TreePlus
```

## Usage examples
```powershell
# Basic Tree of folders Only
Show-Tree -Path "C:\Projects"

"Include file and file sizes
Show-Tree -Path "C:\Projects" -ShowFiles -ShowFileSizes


```

## Tests
```powershell
Invoke-Pester -Path .\tests
```
