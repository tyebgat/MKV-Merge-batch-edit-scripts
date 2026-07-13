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
# Preview tracks from the first MKV found
#------------------------------------------------------------
$firstFile = Get-ChildItem *.mkv | Select-Object -First 1

if (-not $firstFile) {
    Write-Host "No MKV files found in current directory." -ForegroundColor Red
    exit
}

Write-Host "`n=== Track List (from: $($firstFile.Name)) ===" -ForegroundColor Cyan

$trackInfo = & mkvmerge -J $firstFile.Name | ConvertFrom-Json

$subtitleTracks = $trackInfo.tracks | Where-Object { $_.type -eq 'subtitles' }

if ($subtitleTracks.Count -eq 0) {
    Write-Host "No subtitle tracks found in this file." -ForegroundColor Yellow
} else {
    Write-Host ""
    foreach ($track in $subtitleTracks) {
        $langCode = if ($track.properties.language_ietf) {
            $track.properties.language_ietf
        } else {
            $track.properties.language
        }
        $langName = if ($langMap.ContainsKey($langCode)) { $langMap[$langCode] } else { $langCode }
        $trackName = if ($track.properties.track_name) { $track.properties.track_name } else { '(no name)' }
        $isDefault = if ($track.properties.default_track) { ' [default]' } else { '' }
        $isForced  = if ($track.properties.forced_track)  { ' [forced]'  } else { '' }

        Write-Host "  ID $($track.id)  |  $($track.codec)  |  $langName ($langCode)  |  $trackName$isDefault$isForced"
    }
    Write-Host ""
}

#------------------------------------------------------------
# Prompt user for subtitle tracks to extract
#------------------------------------------------------------
Write-Host "=== Subtitle Track Configuration ===" -ForegroundColor Cyan
Write-Host "Enter the track IDs you want to extract."
Write-Host "You will be asked which one to set as default.`n"

$subsToKeep = @{}

while ($true) {
    $input1 = Read-Host "Enter track ID to extract (or press Enter to finish)"
    if ($input1 -eq '') {
        if ($subsToKeep.Count -eq 0) {
            Write-Host " No tracks entered - all subtitle tracks will be extracted.`n" -ForegroundColor Red
        }
        break
    }

    if ($input1 -match '^\d+$') {
        $subsToKeep[[int]$input1] = $false
        Write-Host "  Track $input1 added." -ForegroundColor Green
    } else {
        Write-Host "  Invalid input1. Please enter a numeric track ID." -ForegroundColor Red
    }
}

New-Item -ItemType Directory -Force -Path "extracted_subs" | Out-Null
$extSubsDir = ".\extracted_subs"
$should_continue = $true

#=================================================
# CHECK IF THERE ARE CONTENTS IN 'extracted_subs' FOLDER
#=================================================
if (Test-Path $extSubsDir) {
    $contents = Get-ChildItem -Path $extSubsDir
    if ($contents.Count -eq 0){
        Write-Host "Folder is empty, Moving Files..." -ForegroundColor Green
    } else {
        Write-Host "Found $($contents.Count) item(s) in 'extracted_subs': " -ForegroundColor Yellow
        $contents | ForEach-Object {Write-Host "- $($_.Name)"}
                
        $confirm = Read-Host "`n Delete File Content(s)? [If not then the operation will be canceled]: "

        if ($confirm -eq 'y'){
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

#------------------------------------------------------------
# Extract subtitle tracks from all MKV files
#------------------------------------------------------------
if ($should_continue) {

Write-Host "`n=== Extracting Subtitles ===" -ForegroundColor Cyan

$mkvFiles = Get-ChildItem *.mkv
$extractedCount = 0

foreach ($mkvFile in $mkvFiles) {
    Write-Host "`nProcessing: $($mkvFile.Name)" -ForegroundColor Cyan

    $fileTrackInfo = & mkvmerge -J $mkvFile.Name | ConvertFrom-Json
    $fileSubTracks = $fileTrackInfo.tracks | Where-Object { $_.type -eq 'subtitles' }

    if ($fileSubTracks.Count -eq 0) {
        Write-Host "  No subtitle tracks found in this file." -ForegroundColor Yellow
        continue
    }

    $tracksToExtract = @()
    if ($subsToKeep.Count -eq 0) {
        $tracksToExtract = $fileSubTracks
    } else {
        foreach ($track in $fileSubTracks) {
            if ($subsToKeep.ContainsKey($track.id)) {
                $tracksToExtract += $track
            }
        }
    }

    if ($tracksToExtract.Count -eq 0) {
        Write-Host "  No matching subtitle tracks found in this file." -ForegroundColor Yellow
        continue
    }

    $extractArgs = @($mkvFile.Name, 'tracks')
    $langCount = @{}

    foreach ($track in $tracksToExtract) {
        $trackId   = $track.id
        $trackCodec = $track.codec

        $langCode = if ($track.properties.language_ietf) {
            $track.properties.language_ietf
        } else {
            $track.properties.language
        }

        $ext = switch -Wildcard ($trackCodec) {
            'SubRip*'                                  { 'srt' }
            'S_TEXT/UTF8'                              { 'srt' }
            'S_TEXT/ASCII'                             { 'srt' }
            '*ASS*'                                    { 'ass' }
            '*SSA*'                                    { 'ass' }
            'S_TEXT/SSA'                               { 'ass' }
            'S_TEXT/ASS'                               { 'ass' }
            'S_HDMV/PGS'                               { 'sup' }
            'S_HDMV/TEXTST'                            { 'textst' }
            'S_VOBSUB'                                 { 'sub' }
            'S_TEXT/WEBVTT'                            { 'vtt' }
            'S_TEXT/USF'                               { 'usf' }
            'S_KATE'                                   { 'ogk' }
            default                                    { 'srt' }
        }

        if (-not $langCount.ContainsKey($langCode)) {
            $langCount[$langCode] = 0
        }
        $langCount[$langCode]++

        if ($langCount[$langCode] -gt 1) {
            $outName = "$($mkvFile.BaseName).${langCode}_$($langCount[$langCode]).${ext}"
        } else {
            $outName = "$($mkvFile.BaseName).${langCode}.${ext}"
        }

        $outPath = Join-Path $extSubsDir $outName
        $extractArgs += "${trackId}:${outPath}"

        Write-Host "  Track $trackId ($trackCodec, $langCode) -> $outName"
    }

    & mkvextract @extractArgs

    if ($?) {
        Write-Host "  Extraction successful: $($mkvFile.Name)" -ForegroundColor Green
        $extractedCount++
    } else {
        Write-Host "  Error extracting from: $($mkvFile.Name)" -ForegroundColor Red
    }
}

Write-Host "`n=== Extraction Complete ===" -ForegroundColor Green
Write-Host "Extracted $extractedCount file(s) into 'extracted_subs' folder."

} # end if ($should_continue)
