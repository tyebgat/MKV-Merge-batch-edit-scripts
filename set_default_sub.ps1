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
# Preview subtitle tracks from the first MKV found
#------------------------------------------------------------
$firstFile = Get-ChildItem *.mkv | Select-Object -First 1
 
if (-not $firstFile) {
    Write-Host "No MKV files found in current directory." -ForegroundColor Red
    exit
}
 
Write-Host "`n=== Subtitle Tracks (from: $($firstFile.Name)) ===" -ForegroundColor Cyan
 
$trackInfo = & mkvmerge -J $firstFile.Name | ConvertFrom-Json
$subtitleTracks = $trackInfo.tracks | Where-Object { $_.type -eq 'subtitles' }
 
if ($subtitleTracks.Count -eq 0) {
    Write-Host "No subtitle tracks found in this file." -ForegroundColor Yellow
    exit
}
 
Write-Host ""
foreach ($track in $subtitleTracks) {
    $langCode = if ($track.properties.language_ietf) {
        $track.properties.language_ietf
    } else {
        $track.properties.language
    }
    $langName  = if ($langMap.ContainsKey($langCode)) { $langMap[$langCode] } else { $langCode }
    $trackName = if ($track.properties.track_name) { $track.properties.track_name } else { '(no name)' }
    $isDefault = if ($track.properties.default_track) { ' [default]' } else { '' }
    $isForced  = if ($track.properties.forced_track)  { ' [forced]'  } else { '' }
 
    Write-Host "  ID $($track.id)  |  $($track.codec)  |  $langName ($langCode)  |  $trackName$isDefault$isForced"
}
Write-Host ""
 
#------------------------------------------------------------
# Prompt user for the one track to set as default
#------------------------------------------------------------
$validIds = $subtitleTracks | ForEach-Object { $_.id }
 
$defaultTrackId = $null
while ($true) {
    $inputVal = Read-Host "Enter the track ID to set as default"
    if ($inputVal -match '^\d+$' -and $validIds -contains [int]$inputVal) {
        $defaultTrackId = [int]$inputVal
        Write-Host "  Track $defaultTrackId will be set as default.`n" -ForegroundColor Green
        break
    } else {
        Write-Host "  Invalid ID. Valid subtitle track IDs are: $($validIds -join ', ')" -ForegroundColor Red
    }
}
 
#------------------------------------------------------------
# Process every MKV in the directory
#------------------------------------------------------------
New-Item -ItemType Directory -Force -Path "original_files" | Out-Null
 
Get-ChildItem *.mkv | ForEach-Object {
    Write-Host "Processing: $($_.Name)"
 
    # Build per-track flags:
    #   - forced:false  on every subtitle track
    #   - default:true  only on the chosen track, false on all others
    $trackParams = @()
    foreach ($track in $subtitleTracks) {
        $tid      = $track.id
        $isChosen = ($tid -eq $defaultTrackId)
 
        $trackParams += "--default-track"
        $trackParams += "${tid}:$($isChosen.ToString().ToLower())"
 
        $trackParams += "--forced-track"
        $trackParams += "${tid}:false"
    }
 
    $mkvmergeArgs = @(
        '-o', "$($_.BaseName)_temp.mkv"
    ) + $trackParams + @($_.Name)
 
    & mkvmerge $mkvmergeArgs
 
    if ($?) {
        Move-Item $_.Name "original_files\"
        Rename-Item "$($_.BaseName)_temp.mkv" $_.Name
        Write-Host "  Done: $($_.Name)" -ForegroundColor Green
    } else {
        Write-Host "  Error processing: $($_.Name)" -ForegroundColor Red
        if (Test-Path "$($_.BaseName)_temp.mkv") {
            Remove-Item "$($_.BaseName)_temp.mkv"
        }
    }
}
 
Write-Host "`nAll files processed!" -ForegroundColor Green
Write-Host "Originals are saved in the 'original_files' folder."