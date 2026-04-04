# MKV Merge batch edit scripts
Scripts that are meant for batch editing, subtitles, audios on folders with various files (like series and movies)

## Table of Contents 

- [What It Is](#what-it-is)
- [Requirements](#requirements)
- [Installation](#installation)
- [Scripts](#scripts)


## **What It Is**

I've been struggling for stuff with my jellyfin server or just library management in general, there are tools that can sort of batch edit files but its clunky and slow most of the time. Which why i made this powershell scripts that uses mkv merge to edit things like subtitles and audio.

After seeing the requirements you'll say "Why not just use MKVToolNix?" well, thats because its not really good for editing batch files, atleast it was enough of a pain to make me create scripts for the things I wanted.

Also this scripts are mostly Meant for editing series in Batch, meaning video files that have the subtitle, audio, etc on the same Track ID. Although using them for individual files still works.

## **REQUIREMENTS:**

- MKV Merge on system PATH
- Python 3.11 or above

## **Installation**

- You need MKV merge to be set as System PATH.
- The easiest way to do this is by Installing MKVToolNix
- During the Installer of MKVToolNix be sure to check  'Add MKVToolNix to the PATH' 

Check if you have it on PATH already by opening up the terminal and typing:
```
mkvmerge --version
```

## **Scripts**

### The Format
To make sure this scripts work make sure you input the directory where your files are.
Ex:
Lets say that in you have a folder called SeriesName and inside its this:

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

So to be in that directory you should copy it from the top of your explorer windows. It should be something like

```
"C:\Users\ExUser\Series\SeriesName"
```

Depending on the script you choose it will only the target the video files or both the subtitle and the video file and it will ignore everything else inside the folder.

### THIS SCRIPTS WILL NOT WORK WITH ANY OITHER VIDEO FILE EXCEPT MKV
As of now there are 5 Scripts in the Program each with its different use.

Each script makes another file of the video with the changes applied. It puts the originals on a folder called "Original Files"

> IMPORTANT:
> If the original files folder is already created and the another or the same script is ran then it will result in the script crashing. Make sure you have deleted the inside of original files and made sure the output video is as you wanted.

THESE SCRIPTS ARE MOSTLY DESIGNED TO OPERATE IN BATCH WITH SERIES WHICH HAVE THE SUBTILTES AND AUDIO ON THE SAME TRACK ID PLACEMENT

Although I've had no problems running them to edit single files like movies.

### 1. Filter Subtitles

As it says it filters subtitles, it gives you the track IDs for each subtitle track of the first file in the folder.

It then prompts you to input the track IDs you want to keep and it will remove any other one, to stop you simply press enter without inputting anything, after which you will be asked which track ID will be set to default.

> Note:
> If another track that is being kept is set as forced or default, it will not override that. For that use the Set default subs script

If one does not input anything and just preses enter the program will delete every subtitle track.

### 2. Embed Subtitles to video

It Embeds the subtitles that match with the video name. 

Ex:
If you have files like this 
```
-SeriesName S01E01.mkv
-SeriesName S01E01.spa.ass
-SeriesName S01E01.eng.ass
```
The program will embed those subtitles to the mkv, after which, the original video file will be moved to "original files" folder while the subtitles will be moced to the "subs" folder

Before Beginning the Embed it will ask which subtitle langauge code to set as default, using the previous example, if I wanted the default subtitle to be the spa.ass file then I will just input the language code "spa".

> Note:
> If another track that is set as forced or default, it will not override that. For that use the Set default subs script


### 3. Set Default Subtitle

Similar to Filter Subtitles, the program gives the track ID list of the first video file in the folder.

The program prompts you which track ID you want to set as default. The difference with the others is that this scripts overrides any forced or default track that has been set before which makes so that only the track ID selected will be set as default.

### 4. Set Default Audio

Functions the same as the Subtitle Variant but instead of showing the Subtitle track ID it shows you the Audio track ID. Which it then changes the default with the users input utilizing the same logic as the subtitle variant.

### 5. Show Track IDs

Grabs the first video file on the folder and then prints the Track IDs of it.


