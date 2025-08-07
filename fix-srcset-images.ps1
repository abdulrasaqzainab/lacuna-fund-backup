param(
    [string]$WorkspacePath = (Get-Location).Path,
    [switch]$DryRun
)

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-ImageExists {
    param(
        [string]$BasePath,
        [string]$ImagePath
    )
    
    $FullPath = Join-Path $BasePath $ImagePath
    return Test-Path $FullPath
}

function Fix-SrcsetPaths {
    param(
        [string]$Path
    )
    
    Write-ColorOutput "Fixing srcset attributes to only include existing images..." -Color "Cyan"
    
    $HtmlFiles = Get-ChildItem -Path $Path -Filter "*.html" -Recurse -File
    $ProcessedCount = 0
    $TotalChanges = 0
    
    foreach ($File in $HtmlFiles) {
        try {
            $Content = Get-Content $File.FullName -Raw -Encoding UTF8
            $OriginalContent = $Content
            $FileChanges = 0
            
            # Find all srcset attributes
            $SrcsetPattern = 'srcset="([^"]*)"'
            $SrcsetMatches = [regex]::Matches($Content, $SrcsetPattern)
            
            foreach ($Match in $SrcsetMatches) {
                $OriginalSrcset = $Match.Groups[1].Value
                
                # Split srcset into individual sources
                $Sources = $OriginalSrcset -split ','
                $ValidSources = @()
                
                foreach ($Source in $Sources) {
                    $Source = $Source.Trim()
                    if ($Source) {
                        # Extract the path (everything before the space and size descriptor)
                        $Parts = $Source -split '\s+'
                        $ImagePath = $Parts[0]
                        
                        # Check if the image exists
                        if (Test-ImageExists -BasePath $Path -ImagePath $ImagePath) {
                            $ValidSources += $Source
                        } else {
                            Write-ColorOutput "    Missing image: $ImagePath" -Color "Yellow"
                        }
                    }
                }
                
                # If we have valid sources, rebuild the srcset
                if ($ValidSources.Count -gt 0) {
                    $NewSrcset = $ValidSources -join ', '
                    if ($NewSrcset -ne $OriginalSrcset) {
                        $Content = $Content.Replace($Match.Groups[0].Value, "srcset=`"$NewSrcset`"")
                        $FileChanges++
                    }
                } else {
                    # If no valid sources, remove the entire srcset attribute
                    $Content = $Content.Replace($Match.Groups[0].Value, '')
                    $FileChanges++
                    Write-ColorOutput "    Removed entire srcset (no valid images)" -Color "Red"
                }
            }
            
            # Only write file if changes were made
            if ($Content -ne $OriginalContent) {
                if ($DryRun) {
                    Write-ColorOutput "  [DRY RUN] Would fix $FileChanges srcset(s) in: $($File.Name)" -Color "Yellow"
                } else {
                    Set-Content -Path $File.FullName -Value $Content -Encoding UTF8 -NoNewline
                    Write-ColorOutput "  Fixed $FileChanges srcset(s) in: $($File.Name)" -Color "Green"
                }
                $ProcessedCount++
                $TotalChanges += $FileChanges
            }
            
        } catch {
            Write-ColorOutput "  Failed to process: $($File.Name) - $($_.Exception.Message)" -Color "Red"
        }
    }
    
    if ($ProcessedCount -eq 0) {
        Write-ColorOutput "  No HTML files needed srcset fixes" -Color "Cyan"
    } else {
        Write-ColorOutput "  Total: Fixed $TotalChanges srcset(s) across $ProcessedCount file(s)" -Color "Green"
    }
    
    return @{ ProcessedFiles = $ProcessedCount; TotalChanges = $TotalChanges }
}

function Show-Summary {
    param(
        [hashtable]$Results
    )
    
    Write-ColorOutput "`nSRCSET CLEANUP SUMMARY" -Color "Cyan"
    Write-ColorOutput "=====================" -Color "Cyan"
    Write-ColorOutput "HTML files with fixed srcsets: $($Results.ProcessedFiles)" -Color "Green"
    Write-ColorOutput "Total srcsets fixed: $($Results.TotalChanges)" -Color "Green"
    
    if ($DryRun) {
        Write-ColorOutput "`nDRY RUN MODE - No actual changes were made" -Color "Yellow"
        Write-ColorOutput "Run without -DryRun parameter to apply changes" -Color "Yellow"
    } else {
        Write-ColorOutput "`nSrcset cleanup completed successfully!" -Color "Green"
    }
}

# Main execution
try {
    Write-ColorOutput "Srcset Image Cleanup Script" -Color "Cyan"
    Write-ColorOutput "===========================" -Color "Cyan"
    Write-ColorOutput "Workspace: $WorkspacePath" -Color "Cyan"
    
    if ($DryRun) {
        Write-ColorOutput "Mode: DRY RUN (preview only)" -Color "Yellow"
    } else {
        Write-ColorOutput "Mode: EXECUTE (making changes)" -Color "Magenta"
    }
    
    Write-ColorOutput ""
    
    # Validate workspace path
    if (-not (Test-Path $WorkspacePath)) {
        throw "Workspace path does not exist: $WorkspacePath"
    }
    
    # Find the HTTrack backup directory
    $HTTrackPath = Join-Path $WorkspacePath "lacunafund-httrack-backup\lacunafund.org"
    if (-not (Test-Path $HTTrackPath)) {
        throw "HTTrack backup directory not found: $HTTrackPath"
    }
    
    Write-ColorOutput "Working in: $HTTrackPath" -Color "Cyan"
    Write-ColorOutput ""
    
    # Execute cleanup
    $Results = Fix-SrcsetPaths -Path $HTTrackPath
    Write-ColorOutput ""
    
    # Show summary
    Show-Summary -Results $Results
    
} catch {
    Write-ColorOutput "Script failed: $($_.Exception.Message)" -Color "Red"
    exit 1
}
