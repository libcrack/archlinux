#!/usr/bin/env bash
# dom may  8 21:14:54 CEST 2016

pkgfile='/tmp/pacman.packages'
aurfile='/tmp/pacman.packages.aur'
unkfile='/tmp/pacman.packages.unknown'

msg() { printf "\e[1m[*]\e[0m ${@}\n"; }

if [ -f ~/.bash_functions ]; then . ~/.bash_functions; fi

if [ $UID -ne 0 ]; then printf "\e[31mGot root?\e[0m\n"; exit 1; fi

pacman_export(){
    msg "Saving pacman package list $pkgfile"
    pacman -Qqe | grep -vx "$(pacman -Qqm)" > "$pkgfile"

    msg "Saving AUR package list $aurfile"
    pacman -Qqm > "$aurfile"

    msg "Saving bins & libs installed unbeknownst to pacman to $unkfile"
    msg "(i.e.: installed via Steam or own install methods)"
    find / -regextype posix-extended -regex "/(sys|srv|proc)|.*/\.ccache/.*" -prune -o -type f \
        -exec bash -c 'file "{}" | grep -E "(32|64)-bit"' \; | awk -F: '{print $1}' | \
        while read -r bin; do pacman -Qo "$bin" &>/dev/null || echo "$bin"; done \
        | > "$unkfile"
}

pacman-import(){
    if [ ! -f "$pkgfile" ]; then error "Cannot open $pkgfile"; exit 2; fi
    if [ ! -f "$aurfile" ]; then error "Cannot open $aurfile"; exit 3; fi
    if [ ! -f "$unkfile" ]; then error "Cannot open $unkfile"; exit 4; fi

    msg "Installing pacman packages from $pkgfile"
    xargs -a "$pkgfile" pacman -S --noconfirm --needed

    msg "Installing AUR packages from $aurfile"
    xargs -a "$pkgfile" pacman -S --noconfirm --needed

    msg "Installing unknown packages from $unkfile"
    xargs -a "$pkgfile" pacman -S --noconfirm --needed
}

case "$1" in
    import) msg "Importing packages list"; pacman_import; exit 0;;
    export) msg "Exporting packages list"; pacman_export; exit 0;;
    *) printf "Usage: $0 <import|export>\n" exit 1;;
esac

