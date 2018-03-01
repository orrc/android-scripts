# Scripts for Android Developers

This repo contains some stuff I use during Android development.

They lean heavily on the super-amazing [`fzf`][0] tool to enable interactive
selection and fuzzy searching.

## `bash_fzf_android.sh`
This contains three Bash functions:

* `apk` — grabs an APK from a connected Android device or emulator, and names it
according to its application ID and version code
* `device` — returns the serial of a connected Android device or emulator
* `install` — allows the selection of APK(s), and installs them onto one or more
connected Android devices or emulators

## `bash_fzf_git.sh`
This contains one Bash function:

* `b` — shows a list of recent Git branches, allows one to be selected, and
subsequently checks it out

## Demos
TODO: Asciinema demos

## Usage
Having copied the scripts somewhere, you can do something like this in your
`~/.bashrc` or equivalent, and then "source" that file:

```
# Android magic
[ -f ~/android/bash_fzf_android.sh ] && source ~/android/bash_fzf_android.sh

# Git magic
[ -f ~/android/bash_fzf_git.sh ] && source ~/android/bash_fzf_git.sh
```

## Compatibility
These scripts have been tested by me on macOS, under Bash 4.x; portability to
other shells or operating systems is unknown, but I've included suspected
incompatibilities in the documentation before each function.

## Licence
    The MIT License (MIT)

    Copyright (c) 2018 Christopher Orr

[0]:https://github.com/junegunn/fzf
