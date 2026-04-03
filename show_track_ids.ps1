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
