#------------------------------------------------------------
# Collect MKV files
#------------------------------------------------------------
$mkvFiles = Get-ChildItem *.mkv

if ($mkvFiles.Count -eq 0) {
    Write-Host "No MKV files found in current directory." -ForegroundColor Red
    exit
}

Write-Host "`n=== Video Transcoding ===`n" -ForegroundColor Cyan
Write-Host "Found $($mkvFiles.Count) MKV file(s) to process`n"

#------------------------------------------------------------
# Video codec selection
#------------------------------------------------------------
Write-Host "Select video codec:" -ForegroundColor Cyan
Write-Host "  1) H.264"
Write-Host "  2) H.265"
Write-Host "  3) AV1`n"
Write-Host "  (AV1 forces software encoding)`n"

$vCodecInput = Read-Host "Choose (1-3, default 1)"
switch -Regex ($vCodecInput) {
    '^2$'  { $vCodec = 'h265' }
    '^3$'  { $vCodec = 'av1'  }
    default { $vCodec = 'h264' }
}
Write-Host "  Selected: $vCodec`n" -ForegroundColor Green

#------------------------------------------------------------
# HW acceleration selection (H.264 / H.265 only)
#------------------------------------------------------------
$hwType = 'none'
if ($vCodec -ne 'av1') {
    Write-Host "Select hardware acceleration:" -ForegroundColor Cyan
    Write-Host "  0) None (software encoding)"
    Write-Host "  1) NVENC  (NVIDIA GPU)"
    Write-Host "  2) QSV    (Intel GPU / iGPU)"
    Write-Host "  3) AMF    (AMD GPU / iGPU)`n"

    $hwInput = Read-Host "Choose (0-3, default 0)"
    switch -Regex ($hwInput) {
        '^1$'  { $hwType = 'nvenc'; Write-Host "  Selected: NVENC`n" -ForegroundColor Green }
        '^2$'  { $hwType = 'qsv';   Write-Host "  Selected: QSV`n"   -ForegroundColor Green }
        '^3$'  { $hwType = 'amf';   Write-Host "  Selected: AMF`n"   -ForegroundColor Green }
        default { $hwType = 'none'; Write-Host "  Selected: Software`n" -ForegroundColor Yellow }
    }
}

#------------------------------------------------------------
# Audio codec selection
#------------------------------------------------------------
Write-Host "Select audio codec:" -ForegroundColor Cyan
Write-Host "  1) AAC"
Write-Host "  2) Opus"
Write-Host "  3) E-AC3"
Write-Host "  4) Passthrough (no re-encode)`n"

$aCodecInput = Read-Host "Choose (1-4, default 2)"
switch -Regex ($aCodecInput) {
    '^1$'  { $aCodec = 'aac';        $aBitrate = '192k' }
    '^3$'  { $aCodec = 'eac3';       $aBitrate = '640k' }
    '^4$'  { $aCodec = 'copy';       $aBitrate = $null }
    default { $aCodec = 'libopus';   $aBitrate = '128k' }
}
Write-Host "  Selected: $aCodec$(if ($aBitrate) { "  @ $aBitrate" })`n" -ForegroundColor Green

#------------------------------------------------------------
# Resolution selection
#------------------------------------------------------------
Write-Host "Select output resolution:" -ForegroundColor Cyan
Write-Host "  0) Same as source"
Write-Host "  1) 1080p  (1920x1080)"
Write-Host "  2) 720p   (1280x720)"
Write-Host "  3) 480p   (854x480)`n"

$resInput = Read-Host "Choose (0-3, default 0)"
switch -Regex ($resInput) {
    '^1$'  { $targetRes = '1080p'; $scaleFilter = "scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease" }
    '^2$'  { $targetRes = '720p';  $scaleFilter = "scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease"  }
    '^3$'  { $targetRes = '480p';  $scaleFilter = "scale='min(854,iw)':'min(480,ih)':force_original_aspect_ratio=decrease"   }
    default { $targetRes = 'source'; $scaleFilter = $null }
}
if ($scaleFilter) {
    Write-Host "  Selected: $targetRes`n" -ForegroundColor Green
} else {
    Write-Host "  Keeping original resolution`n" -ForegroundColor Green
}

#------------------------------------------------------------
# Quality setting
#------------------------------------------------------------
$crfInput = Read-Host "Enter quality (0-51, default 23, lower = better)"
if ($crfInput -match '^\d+$') {
    $crf = [int]$crfInput
} else {
    $crf = 23
}
Write-Host "  Using quality $crf`n" -ForegroundColor Green

#------------------------------------------------------------
# Map video + HW choice to ffmpeg parameters
#------------------------------------------------------------
switch ($hwType) {
    'nvenc' {
        switch ($vCodec) {
            'h264' { $vEnc = 'h264_nvenc'; $vPreset = @('-preset', 'p7'); $vPixFmt = 'nv12'; $vQualParam = '-cq' }
            'h265' { $vEnc = 'hevc_nvenc'; $vPreset = @('-preset', 'p7'); $vPixFmt = 'nv12'; $vQualParam = '-cq' }
        }
    }
    'qsv' {
        switch ($vCodec) {
            'h264' { $vEnc = 'h264_qsv';  $vPreset = @('-preset', 'veryslow'); $vPixFmt = 'nv12'; $vQualParam = '-global_quality' }
            'h265' { $vEnc = 'hevc_qsv';  $vPreset = @('-preset', 'veryslow'); $vPixFmt = 'nv12'; $vQualParam = '-global_quality' }
        }
    }
    'amf' {
        switch ($vCodec) {
            'h264' { $vEnc = 'h264_amf';  $vPreset = @('-quality', 'quality'); $vPixFmt = 'nv12'; $vQualParam = '-qp_p' }
            'h265' { $vEnc = 'hevc_amf';  $vPreset = @('-quality', 'quality'); $vPixFmt = 'nv12'; $vQualParam = '-qp_p' }
        }
    }
    default {
        switch ($vCodec) {
            'h264' { $vEnc = 'libx264';  $vPreset = @('-preset', 'slow');  $vPixFmt = 'yuv420p'; $vQualParam = '-crf' }
            'h265' { $vEnc = 'libx265';  $vPreset = @('-preset', 'slow');  $vPixFmt = 'yuv420p'; $vQualParam = '-crf' }
            'av1'  { $vEnc = 'libsvtav1'; $vPreset = @('-preset', '8');    $vPixFmt = 'yuv420p'; $vQualParam = '-crf' }
        }
    }
}

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

    $ffmpegArgs = @(
        '-y'
        '-i', $videoFile.Name
        '-c:v', $vEnc
    ) + $vPreset + @(
        $vQualParam, $crf
        '-pix_fmt', $vPixFmt
    )

    if ($aCodec -eq 'copy') {
        $ffmpegArgs += '-c:a', 'copy'
    } else {
        $ffmpegArgs += '-c:a', $aCodec, '-b:a', $aBitrate
    }

    $ffmpegArgs += @(
        '-c:s', 'copy'
        '-map', '0'
    )

    if ($scaleFilter) {
        $ffmpegArgs += '-vf', $scaleFilter
    }

    $ffmpegArgs += @(
        '-movflags', '+faststart'
        "$($baseName)_temp.mkv"
    )

    Write-Host "  [$vEnc] encoding" -ForegroundColor Cyan

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
