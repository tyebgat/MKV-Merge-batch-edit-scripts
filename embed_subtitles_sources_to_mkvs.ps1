#------------------------------------------------------------
# Language code to full name mapping
#------------------------------------------------------------
$langMap = @{
    'en'     = 'English'
    'eng'    = 'English'
    'es'     = 'Spanish'
    'spa'    = 'Spanish'
    'es-419' = 'Spanish'
    'es-ES'  = 'Spanish'
    'ja'     = 'Japanese'
    'jpn'    = 'Japanese'
    'pt'     = 'Portuguese'
    'pt-BR'  = 'Portuguese (Brazil)'
    'por'    = 'Portuguese'
    'fr'     = 'French'
    'fre'    = 'French'
    'fra'    = 'French'
    'de'     = 'German'
    'ger'    = 'German'
    'deu'    = 'German'
    'it'     = 'Italian'
    'ita'    = 'Italian'
    'zh'     = 'Chinese'
    'chi'    = 'Chinese'
    'zho'    = 'Chinese'
    'zh-Hans'= 'Chinese (Simplified)'
    'zh-Hant'= 'Chinese (Traditional)'
    'ko'     = 'Korean'
    'kor'    = 'Korean'
    'ar'     = 'Arabic'
    'ara'    = 'Arabic'
    'ru'     = 'Russian'
    'rus'    = 'Russian'
    'hi'     = 'Hindi'
    'hin'    = 'Hindi'
    'und'    = 'Undetermined'
}

#------------------------------------------------------------
# Collect MKV files
#------------------------------------------------------------
$mkvFiles = Get-ChildItem *.mkv

if ($mkvFiles.Count -eq 0) {
    Write-Host "No MKV files found in current directory." -ForegroundColor Red
    exit
}

Write-Host "`n=== Embed Subtitles ===" -ForegroundColor Cyan
Write-Host "Found $($mkvFiles.Count) MKV file(s) to process`n"

#------------------------------------------------------------
# Ask which language to set as default
#------------------------------------------------------------
$defaultLang = Read-Host "Enter the language code to set as default subtitle (e.g. spa, eng) - leave blank for none"
$defaultLang = $defaultLang.Trim().ToLower()

if ($defaultLang -ne '' -and -not $langMap.ContainsKey($defaultLang)) {
    Write-Host "  Warning: '$defaultLang' is not in the language map, will still be used as-is." -ForegroundColor Yellow
}

Write-Host ""

#------------------------------------------------------------
# Process each MKV
#------------------------------------------------------------
New-Item -ItemType Directory -Force -Path "original_files" | Out-Null
New-Item -ItemType Directory -Force -Path "subs"           | Out-Null

Get-ChildItem *.mkv | ForEach-Object {
    $videoFile = $_
    $baseName  = $videoFile.BaseName

    Write-Host "Processing: $($videoFile.Name)"

    # Find all subtitle files matching the base name
    $subtitleFiles = Get-ChildItem "$baseName*.srt", "$baseName*.ass", "$baseName*.ssa" -ErrorAction SilentlyContinue

    if ($subtitleFiles.Count -eq 0) {
        Write-Host "  No matching subtitle files found - skipping.`n" -ForegroundColor Gray
        return
    }

    Write-Host "  Found $($subtitleFiles.Count) subtitle file(s):"
    foreach ($sub in $subtitleFiles) {
        Write-Host "    - $($sub.Name)"
    }

    # Build mkvmerge args — start with the source video
    $mkvmergeArgs = @('-o', "$($baseName)_temp.mkv", $videoFile.Name)

    foreach ($subFile in $subtitleFiles) {
        # Detect language code from filename suffix (e.g. Show.S01E01.eng.srt)
        $langCode = ''
        $trackName = ''

        if ($subFile.Name -match '\.([a-zA-Z]{2,8})\.(srt|ass|ssa)$') {
            $langCode = $matches[1].ToLower()
            $trackName = if ($langMap.ContainsKey($langCode)) { $langMap[$langCode] } else { $langCode.ToUpper() }
        }

        $isDefault = ($langCode -ne '' -and $langCode -eq $defaultLang)

        if ($langCode -ne '') {
            $mkvmergeArgs += "--default-track",  "0:$($isDefault.ToString().ToLower())"
            $mkvmergeArgs += "--language",        "0:$langCode"
            $mkvmergeArgs += "--track-name",      "0:$trackName"
            $mkvmergeArgs += $subFile.Name

            if ($isDefault) {
                Write-Host "    + $trackName ($langCode)  [default]" -ForegroundColor Green
            } else {
                Write-Host "    + $trackName ($langCode)"
            }
        } else {
            $mkvmergeArgs += $subFile.Name
            Write-Host "    + (unknown language)" -ForegroundColor Gray
        }
    }

    # Run mkvmerge
    & mkvmerge $mkvmergeArgs

    if ($?) {
        Move-Item $videoFile.Name "original_files\" -Force
        foreach ($subFile in $subtitleFiles) {
            Move-Item $subFile.FullName "subs\" -Force
        }
        Rename-Item "$($baseName)_temp.mkv" $videoFile.Name -Force
        Write-Host "  Done: $($videoFile.Name)`n" -ForegroundColor Green
    } else {
        Write-Host "  Error processing: $($videoFile.Name)`n" -ForegroundColor Red
        if (Test-Path "$($baseName)_temp.mkv") {
            Remove-Item "$($baseName)_temp.mkv" -Force
        }
    }
}

Write-Host "All files processed!" -ForegroundColor Green
Write-Host "Originals are saved in the 'original_files' folder."
Write-Host "Subtitle files are saved in the 'subs' folder."