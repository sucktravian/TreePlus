Describe "Show-Tree" {

    BeforeAll {
        # Mock Get-ChildItem to return controlled test data
        Mock -CommandName Get-ChildItem -MockWith {
            return @(
                [PSCustomObject]@{ Name = "FolderA"; PSIsContainer = $true; FullName = "$PSScriptRoot\FolderA"; Attributes = "" },
                [PSCustomObject]@{ Name = "File1.txt"; PSIsContainer = $false; Extension = ".txt"; Length = 1234; Attributes = "" }
            )
        }
    }

    It "Should run without error on a simple directory" {
        { Show-Tree -Path "$PSScriptRoot" -Depth 1 } | Should -Not -Throw
    }

    It "Should return Markdown output when -MarkdownOutput is used" {
        Show-Tree -Path "$PSScriptRoot" -MarkdownOutput -ShowFiles -OutputFile "$PSScriptRoot\output.md"
        Test-Path "$PSScriptRoot\output.md" | Should -BeTrue
    }

    It "Should skip hidden folders when -IncludeHidden is not set" {
        $output = Show-Tree -Path "$PSScriptRoot" -ShowFiles -MarkdownOutput
        $output | Should -Not -Match '\.git'
    }
}
