# MKV Merge batch edit scripts
An entirely portable CLI tool the uses mkvmerge and ffmpeg to do some basic batch processing on mkvs.

## Table of Contents

- [What It Is](#what-it-is)
- [Installation](#installation)
- [Scripts](#scripts)


## **What It Is**

I've been struggling with stuff for my Jellyfin server and library management in general. There are tools that can sort of batch edit files but they're clunky and slow most of the time, which is why I made these PowerShell scripts that use MKV Merge to edit things like subtitles and audio.

Both MkvMerge and FFmpeg are bundled with the program, no need for any other dependencies.

These scripts are mostly meant for editing series in batch, meaning video files that have the subtitles, audio, etc. on the same Track ID. Although using them for individual files still works.

## **Installation**

- Download the Latest version in Releases
- Launch the .exe

## **Scripts**

### The Format
To make sure these scripts work, make sure you input the directory where your files are.

Ex:
Let's say you have a folder called SeriesName and inside it has this:
```
- SeriesName S01E01.mkv
- SeriesName S01E02.mkv
- SeriesName S01E03.mkv
- SeriesName S01E04.mkv
- SeriesName S01E05.mkv
- SeriesName S01E01.spa.ass
- SeriesName S01E02.spa.ass
- SeriesName S01E03.spa.ass
- SeriesName S01E04.spa.ass
- SeriesName S01E05.spa.ass
```

So to be in that directory you should copy it from the top of your Explorer window. It should be something like:
```
"C:\Users\ExUser\Series\SeriesName"
```

Depending on the script you choose it will only target the video files or both the subtitle and video files, and it will ignore everything else inside the folder.

### THESE SCRIPTS WILL NOT WORK WITH ANY VIDEO FILE OTHER THAN MKV
As of now there are 5 scripts in the program, each with a different use.

Each script creates another file of the video with the changes applied and puts the originals in a folder called "Original Files".

THESE SCRIPTS ARE MOSTLY DESIGNED TO OPERATE IN BATCH WITH SERIES WHICH HAVE THE SUBTITLES AND AUDIO ON THE SAME TRACK ID PLACEMENT

Although they work fine for editing single files like movies as well.

### 1. Filter Subtitles

As it says, it filters subtitles. It gives you the track IDs for each subtitle track of the first file in the folder.

It then prompts you to input the track IDs you want to keep and will remove any others. To stop, simply press Enter without inputting anything, after which you will be asked which track ID to set as default.

> Note:
> If another track that is being kept is set as forced or default, it will not override that. For that use the Set Default Subs script.

*If you do not input anything and just press Enter, the program will delete every subtitle track.*

### 2. Embed Subtitles to Video

Embeds the subtitles that match the video filename.

Ex:
If you have files like this:
```
- SeriesName S01E01.mkv
- SeriesName S01E01.spa.ass
- SeriesName S01E01.eng.ass
```
The program will embed those subtitles into the MKV. After which, the original video file will be moved to the "original_files" folder while the subtitles will be moved to the "subs" folder.

Before beginning the embed it will ask which subtitle language code to set as default. Using the previous example, if you want the default subtitle to be the spa.ass file then just input the language code "spa".

> Note:
> If another track is set as forced or default, it will not override that. For that use the Set Default Subs script.

### 3. Extract Subtitle

Gives you the track ID list from the first video on the folder.

The program prompts you for which subtitle track IDs to extract. It will then extract them into a folder named "Extracted subs"

### 4. Set Default Subtitle

Similar to Filter Subtitles, the program gives the track ID list of the first video file in the folder.

The program prompts you for which track ID to set as default. The difference with the others is that this script overrides any forced or default track that has been set before, making it so that only the selected track ID will be set as default.

### 5. Set Default Audio

Functions the same as the subtitle variant but instead of showing the subtitle track IDs it shows the audio track IDs, then changes the default based on the user's input using the same logic as the subtitle variant.

### 6. Transcode using FFmpeg

Transcodes all mkvs files in the directory you inputed.
Transcodes are all in 8 bit video.

I needed a script to modify my media so it can all be direct play without any external clients.

It will first prompt you if you want to insert your own ffmpeg arguments or go through a guided proccess.

If you select a guided process then the next menu will follow:

#### Select Video Codec:
```
Select video codec:
  1) H.264
  2) H.265
  3) AV1

  (AV1 forces software encoding)  
```

Lets you choose which codec to put your video in. All of these will be in 8 bit color.
H.264 is the one most universally suported.
AV1 is not supported by most hardware acceleration so it will force you to use cpu rendering.

#### Hardware Acceleration:
```
Select hardware acceleration:
  0) None (software encoding)
  1) NVENC  (NVIDIA GPU)
  2) QSV    (Intel GPU / iGPU)
  3) AMF    (AMD GPU / iGPU)
```

Lets you choose which Hardware acceleration to use, this is way faster than using cpu/software rendering.
You will need to have your gpu drivers installed to get this feature.

#### Aduio Codec:
```
Select audio codec:
  1) AAC
  2) Opus
  3) E-AC3
  4) Passthrough (no re-encode)
```

Lets you choose the audio codec.
- AAC is essentially MP4. All devices support this.
- Opus a better mp4, higher quality and smaller size. Basically All devices support it.
- E-AC3 also known as Dolby Audio. Only devices that support dolby audio can play it.
- Passthrough. The audio codec will be the same as the source file.

#### Select Resolution:
```
Select output resolution:
  0) Same as source
  1) 1080p  (1920x1080)
  2) 720p   (1280x720)
  3) 480p   (854x480)
```

Pretty self explanatory.

#### Enter quality:
```
Enter quality (0-51, default 23, lower = better):
```

It will prompt you to enter the constant quality of the file. The lower this value is the higher the quality. 
Although putting this value too low will get you enormous file sizes, I recommend putting 20-21 for live actions films and just leaving it at 23 for Animated shows/films.

### 7. Show Track IDs (first file)

Shows a Table of all the Track IDs of the first file in the inputted folder.