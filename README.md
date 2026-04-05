# MKV Merge batch edit scripts
Scripts that are meant for batch editing subtitles and audio on folders with various files (like series and movies)

## Table of Contents

- [What It Is](#what-it-is)
- [Requirements](#requirements)
- [Installation](#installation)
- [Scripts](#scripts)


## **What It Is**

I've been struggling with stuff for my Jellyfin server and library management in general. There are tools that can sort of batch edit files but they're clunky and slow most of the time, which is why I made these PowerShell scripts that use MKV Merge to edit things like subtitles and audio.

After seeing the requirements you'll say "Why not just use MKVToolNix?" Well, that's because it's not really good for editing batch files, at least it was enough of a pain to make me create scripts for the things I wanted.

These scripts are mostly meant for editing series in batch, meaning video files that have the subtitles, audio, etc. on the same Track ID. Although using them for individual files still works.

## **REQUIREMENTS:**

- MKV Merge on system PATH
- Python 3.11 or above

## **Installation**

- You need MKV Merge to be set as System PATH.
- The easiest way to do this is by installing MKVToolNix.
- During the installer of MKVToolNix be sure to check 'Add MKVToolNix to the PATH'

Check if you have it on PATH already by opening up the terminal and typing:
```
mkvmerge --version
```

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

If you do not input anything and just press Enter, the program will delete every subtitle track.

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

### 3. Set Default Subtitle

Similar to Filter Subtitles, the program gives the track ID list of the first video file in the folder.

The program prompts you for which track ID to set as default. The difference with the others is that this script overrides any forced or default track that has been set before, making it so that only the selected track ID will be set as default.

### 4. Set Default Audio

Functions the same as the subtitle variant but instead of showing the subtitle track IDs it shows the audio track IDs, then changes the default based on the user's input using the same logic as the subtitle variant.

### 5. Show Track IDs

Grabs the first video file in the folder and prints all of its Track IDs.