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
# Mode selection — guided or custom ffmpeg arguments
#------------------------------------------------------------
Write-Host "Select mode:" -ForegroundColor Cyan
Write-Host "  1) Guided setup"
Write-Host "  2) Custom ffmpeg arguments`n"

$modeInput = Read-Host "Choose (1-2, default 1)"
$useCustomArgs = $modeInput -and $modeInput.Trim() -eq '2'

if ($useCustomArgs) {
    Write-Host "Enter custom ffmpeg arguments:" -ForegroundColor Cyan
    Write-Host "  The input file (-i) and output filename are added automatically." -ForegroundColor Gray
    Write-Host "  -sn -dn are added automatically (subs/data handled by mkvmerge post-process)." -ForegroundColor Gray
    $customArgs = Read-Host "Custom args"
    $useCustomArgs = $customArgs -and $customArgs.Trim() -ne ''
    if ($useCustomArgs) {
        Write-Host "  Using custom arguments`n" -ForegroundColor Green
    } else {
        Write-Host "  No args entered, falling back to guided setup`n" -ForegroundColor Yellow
    }
}

if (-not $useCustomArgs) {
    #------------------------------------------------------------
    # Video codec selection
    #------------------------------------------------------------
    Write-Host "Select video codec:" -ForegroundColor Cyan
    Write-Host "  1) H.264"
    Write-Host "  2) H.265"
    Write-Host "  3) AV1"
    Write-Host "  4) Video Passthrough `n"
    Write-Host "  (AV1 forces software encoding)`n"

    $vCodecInput = Read-Host "Choose (1-3, default 1)"
    switch -Regex ($vCodecInput) {
        '^2$'  { $vCodec = 'h265' }
        '^3$'  { $vCodec = 'av1'  }
        '^4$'  { $vCodec = 'copy'}
        default { $vCodec = 'h264' }
    }
    Write-Host "  Selected: $vCodec`n" -ForegroundColor Green

    #------------------------------------------------------------
    # Bit depth selection
    #------------------------------------------------------------
    $bitDepth = 8
    if ($vCodec -ne 'copy') {
        Write-Host "Select bit depth:" -ForegroundColor Cyan
        Write-Host "  1) 8-bit"
        Write-Host "  2) 10-bit`n"

        $bitInput = Read-Host "Choose (1-2, default 1)"
        if ($bitInput -eq '2') { $bitDepth = 10 }
        Write-Host "  Selected: ${bitDepth}-bit`n" -ForegroundColor Green
    }

    #------------------------------------------------------------
    # HW acceleration selection (H.264 / H.265 only)
    #------------------------------------------------------------
    $hwType = 'none'
    if ($vCodec -ne 'av1' -and $vCodec -ne 'copy') {
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
    Write-Host "  1) AAC (192kb)"
    Write-Host "  2) Opus (128kb)"
    Write-Host "  3) E-AC3 (640kb)"
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
    # Encoder preset selection
    #------------------------------------------------------------
    $vPresetChoice = 'medium'
    if ($vCodec -ne 'copy') {
        Write-Host "Select encoder preset:" -ForegroundColor Cyan
        Write-Host "  1) ultrafast"
        Write-Host "  2) superfast"
        Write-Host "  3) veryfast"
        Write-Host "  4) faster"
        Write-Host "  5) fast"
        Write-Host "  6) medium"
        Write-Host "  7) slow"
        Write-Host "  8) slower"
        Write-Host "  9) veryslow`n"
        Write-Host "  (The slower the preset the better the compression)`n"

        $presetInput = Read-Host "Choose (1-9, default 6)"
        switch -Regex ($presetInput) {
            '^1$'  { $vPresetChoice = 'ultrafast' }
            '^2$'  { $vPresetChoice = 'superfast' }
            '^3$'  { $vPresetChoice = 'veryfast' }
            '^4$'  { $vPresetChoice = 'faster' }
            '^5$'  { $vPresetChoice = 'fast' }
            '^7$'  { $vPresetChoice = 'slow' }
            '^8$'  { $vPresetChoice = 'slower' }
            '^9$'  { $vPresetChoice = 'veryslow' }
            default { $vPresetChoice = 'medium' }
        }
        Write-Host "  Selected: $vPresetChoice`n" -ForegroundColor Green
    }

    if ($vCodec -ne 'copy') {
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
    } else {
        $scaleFilter = $null
    }

    if ($vCodec -ne 'copy') {
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
    }

    #------------------------------------------------------------
    # Map video + HW choice to ffmpeg parameters
    #------------------------------------------------------------
    if ($vCodec -ne 'copy') {
        switch ($hwType) {
            'nvenc' {
                $nvencMap = @{ 'ultrafast' = 'p1'; 'superfast' = 'p2'; 'veryfast' = 'p3'; 'faster' = 'p4'; 'fast' = 'p4'; 'medium' = 'p5'; 'slow' = 'p6'; 'slower' = 'p7'; 'veryslow' = 'p7' }
                $nvencPreset = if ($nvencMap.ContainsKey($vPresetChoice)) { $nvencMap[$vPresetChoice] } else { 'p5' }
                switch ($vCodec) {
                    'h264' { $vEnc = 'h264_nvenc'; $vPreset = @('-preset', $nvencPreset, '-rc', 'vbr'); $vPixFmt = 'nv12'; $vQualParam = '-cq' }
                    'h265' { $vEnc = 'hevc_nvenc'; $vPreset = @('-preset', $nvencPreset, '-rc', 'vbr'); $vPixFmt = if ($bitDepth -eq 10) { 'p010le' } else { 'nv12' }; $vQualParam = '-cq' }
                }
            }
            'qsv' {
                $qsvMap = @{ 'ultrafast' = 'veryfast'; 'superfast' = 'veryfast'; 'veryfast' = 'veryfast'; 'faster' = 'faster'; 'fast' = 'fast'; 'medium' = 'medium'; 'slow' = 'slow'; 'slower' = 'slower'; 'veryslow' = 'veryslow' }
                $qsvPreset = if ($qsvMap.ContainsKey($vPresetChoice)) { $qsvMap[$vPresetChoice] } else { 'medium' }
                switch ($vCodec) {
                    'h264' { $vEnc = 'h264_qsv';  $vPreset = @('-preset', $qsvPreset); $vPixFmt = if ($bitDepth -eq 10) { 'p010le' } else { 'nv12' }; $vQualParam = '-global_quality' }
                    'h265' { $vEnc = 'hevc_qsv';  $vPreset = @('-preset', $qsvPreset); $vPixFmt = if ($bitDepth -eq 10) { 'p010le' } else { 'nv12' }; $vQualParam = '-global_quality' }
                }
            }
            'amf' {
                switch ($vCodec) {
                    'h264' { $vEnc = 'h264_amf';  $vPreset = @('-quality', 'quality'); $vPixFmt = if ($bitDepth -eq 10) { 'p010le' } else { 'nv12' }; $vQualParam = '-qp_p' }
                    'h265' { $vEnc = 'hevc_amf';  $vPreset = @('-quality', 'quality'); $vPixFmt = if ($bitDepth -eq 10) { 'p010le' } else { 'nv12' }; $vQualParam = '-qp_p' }
                }
            }
            default {
                $svtMap = @{ 'ultrafast' = '13'; 'superfast' = '11'; 'veryfast' = '9'; 'faster' = '7'; 'fast' = '6'; 'medium' = '8'; 'slow' = '4'; 'slower' = '2'; 'veryslow' = '0' }
                switch ($vCodec) {
                    'h264' { $vEnc = 'libx264';  $vPreset = @('-preset', $vPresetChoice); $vPixFmt = if ($bitDepth -eq 10) { 'yuv420p10le' } else { 'yuv420p' }; $vQualParam = '-crf' }
                    'h265' { $vEnc = 'libx265';  $vPreset = @('-preset', $vPresetChoice); $vPixFmt = if ($bitDepth -eq 10) { 'yuv420p10le' } else { 'yuv420p' }; $vQualParam = '-crf' }
                    'av1'  { $vEnc = 'libsvtav1'; $vPreset = @('-preset', $svtMap[$vPresetChoice]); $vPixFmt = if ($bitDepth -eq 10) { 'yuv420p10le' } else { 'yuv420p' }; $vQualParam = '-crf' }
                }
            }
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

    #=================================
    #CUSTOM ARGUMENTS
    #=================================
    if ($useCustomArgs) {
        $currentArgs = $customArgs
        $success = $false
        while (-not $success) {
            $ieCmd = "& ffmpeg -y -i '$($videoFile.Name)' -sn -dn $currentArgs '$($baseName)_temp.mkv' 2>&1"
            $output = Invoke-Expression $ieCmd
            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0) {
                $success = $true
            } else {
                Write-Host "`nFFmpeg error:" -ForegroundColor Red
                $output | ForEach-Object { Write-Host "$_" -ForegroundColor Yellow }
                Write-Host "" -ForegroundColor Yellow

                $newArgs = Read-Host "Enter corrected arguments (or press Enter to skip this file)"
                if ($newArgs -and $newArgs.Trim() -ne '') {
                    $currentArgs = $newArgs
                    $customArgs = $newArgs
                } else {
                    break
                }
            }
        }

        if ($exitCode -eq 0) {
            if ($should_continue) {
                Write-Host "Merging original metadata (subs, chapters, attachments) with transcoded file..." -ForegroundColor Cyan
                Move-Item $videoFile.Name "original_files\" -Force

                & mkvmerge -o $videoFile.Name --no-audio --no-video "original_files\$($videoFile.Name)" "$($baseName)_temp.mkv" 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Remove-Item "$($baseName)_temp.mkv" -Force
                    Write-Host "  Done: $($videoFile.Name)`n" -ForegroundColor Green
                } else {
                    Write-Host "  Warning: mkvmerge failed, using transcoded file without metadata" -ForegroundColor Yellow
                    Rename-Item "$($baseName)_temp.mkv" $videoFile.Name -Force
                    Write-Host "  Done: $($videoFile.Name)`n" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "  Skipped: $($videoFile.Name)`n" -ForegroundColor Yellow
            if (Test-Path "$($baseName)_temp.mkv") {
                Remove-Item "$($baseName)_temp.mkv" -Force
            }
        }
    } else {
        $ffmpegArgs = @(
            '-y'
            '-i', $videoFile.Name
        )

        if ($vCodec -eq 'copy') {
            $ffmpegArgs += '-c:v', 'copy'
        } else {
            $ffmpegArgs += '-c:v', $vEnc
            $ffmpegArgs += $vPreset
            $ffmpegArgs += $vQualParam, $crf
            $ffmpegArgs += '-pix_fmt', $vPixFmt
        }

        if ($aCodec -eq 'copy') {
            $ffmpegArgs += '-c:a', 'copy'
        } else {
            $ffmpegArgs += '-c:a', $aCodec, '-b:a', $aBitrate
        }

        $ffmpegArgs += @(
            '-map', '0:v', '-map', '0:a'
            '-sn', '-dn'
        )

        if ($scaleFilter) {
            $ffmpegArgs += '-vf', $scaleFilter
        }

        $ffmpegArgs += "$($baseName)_temp.mkv"

        if ($vCodec -eq 'copy') {
            Write-Host "  [video passthrough] encoding audio" -ForegroundColor Cyan
        } else {
            Write-Host "  [$vEnc] encoding" -ForegroundColor Cyan
        }

        Write-Host "`n  ffmpeg $($ffmpegArgs -join ' ')`n" -ForegroundColor Magenta
        Write-Host "  Beginning transcode..." -ForegroundColor Green
        Start-Sleep -Seconds 3

        & ffmpeg $ffmpegArgs 2>&1 | ForEach-Object { Write-Host "$_" -ForegroundColor Yellow }

        if ($LASTEXITCODE -eq 0) {
            if ($should_continue) {
                Write-Host "Merging original metadata (subs, chapters, attachments) with transcoded file..." -ForegroundColor Cyan
                Move-Item $videoFile.Name "original_files\" -Force

                & mkvmerge -o $videoFile.Name --no-audio --no-video "original_files\$($videoFile.Name)" "$($baseName)_temp.mkv" 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Remove-Item "$($baseName)_temp.mkv" -Force
                    Write-Host "  Done: $($videoFile.Name)`n" -ForegroundColor Green
                } else {
                    Write-Host "  Warning: mkvmerge failed, using transcoded file without metadata" -ForegroundColor Yellow
                    Rename-Item "$($baseName)_temp.mkv" $videoFile.Name -Force
                    Write-Host "  Done: $($videoFile.Name)`n" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "  Error processing: $($videoFile.Name)`n" -ForegroundColor Red
            if (Test-Path "$($baseName)_temp.mkv") {
                Remove-Item "$($baseName)_temp.mkv" -Force
            }
        }
    }
}

Write-Host "All files processed!" -ForegroundColor Green
Write-Host "Originals are saved in the 'original_files' folder."
