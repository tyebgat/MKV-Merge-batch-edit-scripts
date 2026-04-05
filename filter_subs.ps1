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
# Prompt user for subtitle tracks to keep
#------------------------------------------------------------
Write-Host "=== Subtitle Track Configuration ===" -ForegroundColor Cyan
Write-Host "Enter the track IDs you want to keep."
Write-Host "You will be asked which one to set as default.`n"

$subsToKeep = @{}

while ($true) {
    $input1 = Read-Host "Enter track ID to keep (or press Enter to finish)"
    if ($input1 -eq '') {
        if ($subsToKeep.Count -eq 0) {
            Write-Host " No tracks entered - all subtitle tracks will be deleted.`n" -ForegroundColor Red
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

# Ask which track should be default (only if tracks were selected)
if ($subsToKeep.Count -gt 0) {
    Write-Host "`nTracks added: $($subsToKeep.Keys -join ', ')"
    while ($true) {
        $defaultTrack = Read-Host "Which track ID should be the default?"
        if ($subsToKeep.ContainsKey([int]$defaultTrack)) {
            $subsToKeep[[int]$defaultTrack] = $true
            Write-Host "  Track $defaultTrack set as default.`n" -ForegroundColor Green
            break
        } else {
            Write-Host "  Track $defaultTrack is not in your list. Choose from: $($subsToKeep.Keys -join ', ')" -ForegroundColor Red
        }
    }
}

#------------------------------------------------------------
# THE TRUE STATE INDICATES THE DEFAULT SUBTITLE
#------------------------------------------------------------

# Create backup directory
New-Item -ItemType Directory -Force -Path "original_files" | Out-Null
$originalFilesDir = ".\original_files"
$should_continue = $true

#=================================================
# CHECK IF THERE ARE CONTENTS IN 'original_files' FOLDER
#=================================================
if (Test-Path $originalFilesDir) {
    $contents = Get-ChildItem -Path $originalFilesDir
    if ($contents.Count -eq 0){
        Write-Host "Folder is empty, Moving Files..." -ForegroundColor Green
    } else {
    Write-Host "Found $($contents.Count) item(s) in 'Original Files': " -ForegroundColor Yellow
    $contents | ForEach-Object {Write-Host "- $($_.Name)"}
                
    $confirm = Read-Host "`n Delete File Content(s)? [If not then the operation will be canceled] [y/n]: "

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

# Process each MKV file
Get-ChildItem *.mkv | ForEach-Object { 
    $videoFile = $_
    $baseName  = $videoFile.BaseName
    Write-Host "Processing: $($videoFile.Name)"
    
    # Get track info via mkvmerge JSON output
    $trackInfo = & mkvmerge -J $videoFile.Name | ConvertFrom-Json
    
    # Build the subtitle tracks parameter
    $subTracksParam = ($subsToKeep.Keys | Sort-Object) -join ','
    
    # Build default track + track name parameters
    $trackParams = @()
    foreach ($trackId in $subsToKeep.Keys) {

        # Set default state
        $isChosen = ($trackId -eq [int]$defaultTrack)

        $trackParams += "--default-track"
        $trackParams += "${trackID}:$($isChosen.ToString().ToLower())"

        # Find the track in JSON and grab its language
        $track = $trackInfo.tracks | Where-Object { $_.id -eq $trackId }
        if ($track) {
            $langCode = if ($track.properties.language_ietf) { 
                $track.properties.language_ietf 
            } else { 
                $track.properties.language 
            }

            if ($langCode) {
                $langName = if ($langMap.ContainsKey($langCode)) { 
                    $langMap[$langCode] 
                } else { 
                    $langCode 
                }

                Write-Host "  Track $trackId language: $langCode -> $langName"
                $trackParams += "--track-name"
                $trackParams += "${trackId}:${langName}"
            }
        } else {
            Write-Host "  Track $trackId not found in file, skipping..." -ForegroundColor Yellow
        }
    }
    
    # Execute mkvmerge with all parameters
    if ($subsToKeep.Count -eq 0) {
        $mkvmergeArgs = @(
        '-o', "$($baseName)_temp.mkv"
        '--no-subtitles'
        $_.Name
    )
    } else{
        $mkvmergeArgs = @(
            '-o', "$($baseName)_temp.mkv"
            '--subtitle-tracks', $subTracksParam
        ) + $trackParams + @($videoFile.Name)
    }
    & mkvmerge $mkvmergeArgs
    
    if($?) { 
        if ($should_continue){
            Write-Host "Moving Files to original files folder..." -ForegroundColor Green
            Move-Item $videoFile.Name "original_files\" -Force
            Rename-Item "$($baseName)_temp.mkv" $videoFile.Name -Force
            Write-Host "Completed: $($baseName)" -ForegroundColor Green
        }
    } else {
        Write-Host "Error processing: $($_.Name)" -ForegroundColor Red
        Write-Host "Removing Created Files... " -ForegroundColor Red
        if (Test-Path "$($baseName)_temp.mkv") {
            Remove-Item "$($baseName)_temp.mkv" -Force
        }
    }
}

Write-Host "`nAll files processed!" -ForegroundColor Green
Write-Host "Original files are in the 'original_files' folder"