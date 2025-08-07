# PowerShell script to fix broken CSS and JS paths in HTML files

$baseDir = "c:\Users\zaina\OneDrive\Documents\GitHub\lacuna-fund-backup\lacunafund-httrack-backup\lacunafund.org"

# Get all HTML files
$htmlFiles = Get-ChildItem -Path $baseDir -Recurse -Include "*.html"

foreach ($file in $htmlFiles) {
    Write-Host "Processing: $($file.FullName)"
    
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Calculate relative path to wp-includes from current file
    $relativePath = $file.DirectoryName.Replace($baseDir, "").TrimStart('\')
    $depth = ($relativePath -split '\\').Where({$_ -ne ''}).Count
    
    if ($depth -eq 0) {
        # File is in root of lacunafund.org, use direct path
        $wpIncludesPath = "wp-includes/"
    } else {
        # File is in subdirectory, need to go up
        $wpIncludesPath = "../" * $depth + "wp-includes/"
    }
    
    # Fix CSS paths
    $content = $content -replace "href='wp-includes/css/", "href='$($wpIncludesPath)css/"
    $content = $content -replace "href='../wp-includes/css/", "href='$($wpIncludesPath)css/"
    $content = $content -replace "href='../../wp-includes/css/", "href='$($wpIncludesPath)css/"
    
    # Fix JS paths
    $content = $content -replace "src='wp-includes/js/", "src='$($wpIncludesPath)js/"
    $content = $content -replace "src='../wp-includes/js/", "src='$($wpIncludesPath)js/"
    $content = $content -replace "src='../../wp-includes/js/", "src='$($wpIncludesPath)js/"
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Updated: $($file.Name)"
    }
}

Write-Host "Path fixing completed!"
