# MKV Merge batch edit scripts
Scripts that are meant for batch editing, subtitles, audios on folders with various files (like series and movies)

## Table of Contents 

- [What It Is](#what-it-is)
- [Requirements](#requirements)
- [Installation](#installation)


## **What It Is**

I've been struggling for stuff with my jellyfin server or just library management in general, there are tools that can sort of batch edit files but its clunky and slow most of the time. Which why i made this powershell scripts that uses mkv merge to edit things like subtitles and audio.

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