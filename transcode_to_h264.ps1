#------------------------------------------------------------
# Collect MKV files
#------------------------------------------------------------
$mkvFiles = Get-ChildItem *.mkv

if ($mkvFiles.Count -eq 0) {
    Write-Host "No MKV files found in current directory." -ForegroundColor Red
    exit
}

Write-Host "`n=== Transcode to H.264 8-bit + AAC ===" -ForegroundColor Cyan
Write-Host "Found $($mkvFiles.Count) MKV file(s) to process`n"

#------------------------------------------------------------
# CRF quality setting
#------------------------------------------------------------
$crfInput = Read-Host "Enter CRF quality (0-51, default 23, lower = better quality)"
if ($crfInput -match '^\d+$') {
    $crf = [int]$crfInput
} else {
    $crf = 23
}
Write-Host "  Using CRF $crf`n" -ForegroundColor Green

#------------------------------------------------------------
# NVIDIA GPU hardware acceleration
#------------------------------------------------------------
$useNvidia = $false
$nvidiaInput = Read-Host "Do you have an NVIDIA GPU? Use hardware acceleration (h264_nvenc)? (y/N)"
if ($nvidiaInput.Trim().ToLower() -eq 'y') {
    $useNvidia = $true
    Write-Host "  Using NVIDIA NVENC hardware encoding" -ForegroundColor Green
} else {
    Write-Host "  Using software encoding (libx264)" -ForegroundColor Yellow
}
Write-Host ""

#------------------------------------------------------------
# Process each MKV
#------------------------------------------------------------
New-Item -ItemType Directory -Force -Path "original_files" | Out-Null
$originalFilesDir = ".\original_files"
$should_continue = $true

#=================================================
# CHECK IF THERE ARE CONTENTS IN 'original_files' FOLDER
#=================================================
if (Test-Path $originalFilesDir) {
    $contents = Get-ChildItem -Path $originalFilesDir
    if ($contents.Count -eq 0) {
        Write-Host "Folder is empty, Moving Files..." -ForegroundColor Green
    } else {
        Write-Host "Found $($contents.Count) item(s) in 'Original Files': " -ForegroundColor Yellow
        $contents | ForEach-Object { Write-Host "- $($_.Name)" }

        $confirm = Read-Host "`n Delete File Content(s)? [If not then the operation will be canceled] [y/n]: "

        if ($confirm -eq 'y') {
            $should_continue = $true
            $contents | Remove-Item -Recurse -Force
            Write-Host "Removed Content Files Succesfully... " -ForegroundColor Green
        } else {
            $should_continue = $false
            Write-Host "Cancelling Operation..." -ForegroundColor Red
            exit
        }
    }
}

Get-ChildItem *.mkv | ForEach-Object {
    $videoFile = $_
    $baseName  = $videoFile.BaseName

    Write-Host "Processing: $($videoFile.Name)" -ForegroundColor Yellow

    if ($useNvidia) {
        $ffmpegArgs = @(
            '-y'
            '-i', $videoFile.Name
            '-c:v', 'h264_nvenc'
            '-pix_fmt', 'nv12'
            '-cq', $crf
            '-c:a', 'libopus'
            '-b:a', '128k'
            '-c:s', 'copy'
            '-map', '0'
            '-movflags', '+faststart'
            "$($baseName)_temp.mkv"
        )
        Write-Host "  [NVENC] encoding" -ForegroundColor Cyan
    } else {
        $ffmpegArgs = @(
            '-i', $videoFile.Name
            '-c:v', 'libx264'
            '-preset', 'slow'
            '-crf', $crf
            '-profile:v', 'high'
            '-pix_fmt', 'yuv420p'
            '-c:a', 'libopus'
            '-b:a', '128k'
            '-c:s', 'copy'
            '-movflags', '+faststart'
            '-y'
            "$($baseName)_temp.mkv"
        )
        Write-Host "  [libx264] encoding" -ForegroundColor Cyan
    }

    & ffmpeg $ffmpegArgs 2>&1 | ForEach-Object { Write-Host "$_" -ForegroundColor Yellow }

    if ($LASTEXITCODE -eq 0) {
        if ($should_continue) {
            Write-Host "Moving original to 'original_files' folder..." -ForegroundColor Green
            Move-Item $videoFile.Name "original_files\" -Force
            Rename-Item "$($baseName)_temp.mkv" $videoFile.Name -Force
            Write-Host "  Done: $($videoFile.Name)`n" -ForegroundColor Green
        }
    } else {
        Write-Host "  Error processing: $($videoFile.Name)`n" -ForegroundColor Red
        if (Test-Path "$($baseName)_temp.mkv") {
            Remove-Item "$($baseName)_temp.mkv" -Force
        }
    }
}

Write-Host "All files processed!" -ForegroundColor Green
Write-Host "Originals are saved in the 'original_files' folder."
