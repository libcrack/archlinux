#!/usr/bin/env bash
# dom may  8 21:14:54 CEST 2016

if [ $UID -ne 0 ]; then printf "\e[31mGot root?\e[0m\n"; exit 1; fi

pkgfile='/tmp/pacman.packages'
aurfile='/tmp/pacman.packages.aur'
unkfile='/tmp/pacman.packages.unknown'

trap captura INT
captura(){ printf "\e[0;31m Ctrl+C: exiting\e[0m\n"; exit 1; }

error(){ printf "\e[0;31m[X]\e[0m ${@}\n" > /dev/stderr; }
info() { printf "\e[0;32m[+]\e[0m ${@}\n" > /dev/stdout; }
warning() { printf "\e[0;33m[\!]\e[0m ${@}\n" > /dev/stdout; }

pacman_export(){
    info "Saving pacman package list $pkgfile"
    pacman -Qqe | grep -vx "$(pacman -Qqm)" > "$pkgfile"

    info "Saving AUR package list $aurfile"
    pacman -Qqm > "$aurfile"

    info "Saving bins & libs installed unbeknownst to pacman to $unkfile"
    info "(i.e.: installed via Steam or own install methods)"
    find / -regextype posix-extended -regex "/(sys|srv|proc)|.*/\.ccache/.*" -prune -o -type f \
        -exec bash -c 'file "{}" | grep -E "(32|64)-bit"' \; | awk -F: '{print $1}' | \
        while read -r bin; do pacman -Qo "$bin" &>/dev/null || echo "$bin"; done \
        | > "$unkfile"
}

pacman-import(){
    if [ ! -f "$pkgfile" ]; then error "Cannot open $pkgfile"; exit 2; fi
    if [ ! -f "$aurfile" ]; then error "Cannot open $aurfile"; exit 3; fi
    if [ ! -f "$unkfile" ]; then error "Cannot open $unkfile"; exit 4; fi

    info "Installing pacman packages from $pkgfile"
    xargs -a "$pkgfile" pacman -S --noconfirm --needed

    info "Installing AUR packages from $aurfile"
    xargs -a "$pkgfile" pacman -S --noconfirm --needed

    info "Installing unknown packages from $unkfile"
    xargs -a "$pkgfile" pacman -S --noconfirm --needed
}

archlinux_mv_rootfs(){
    # man(1) rsync
    #     --devices               preserve device files (super-user only)
    #     --specials              preserve special files
    # -D                          same as --devices --specials
    # -t, --times                 preserve modification times
    # -d, --dirs                  transfer directories without recursing
    # -l, --links                 copy symlinks as symlinks
    # -L, --copy-links            transform symlink into referent file/dir
    #     --copy-unsafe-links     only "unsafe" symlinks are transformed
    #     --safe-links            ignore symlinks that point outside the tree
    #     --munge-links           munge symlinks to make them safer
    # -k, --copy-dirlinks         transform symlink to dir into referent dir
    # -K, --keep-dirlinks         treat symlinked dir on receiver as dir
    # -H, --hard-links            preserve hard links

    local opt="-rDtlH"
    local src="$1"
    local dst="$2"

    if [[ ! -d "$src" ]]; then
        error "Cannot access srcdir $srcdir"
        return 6
    elif [[ ! -d "$dst" ]]; then
        error "Cannot access dst $dstcdir"
        return 7
    fi

    msg "Starting @ $(date)"

    if [ -n "$DEBUG" ]; then
        msg "SRC=$src"
        msg "DST=$dst"
        msg "EXC=$exc"
    fi

    msg "Syncing ${src} => ${dst}"

    sudo rsync "${opt}" \
        --exclude=${exc} ${src} ${dst} \
        && success "No errors"  \
        || error "Errors found"
}
_complete(){
    COMPREPLY=();
    local cur prev opts word;
    cur="${COMP_WORDS[COMP_CWORD]}";
    prev="${COMP_WORDS[COMP_CWORD-1]}";
    opts="import export mvroot";
    if [[ "${cur}" == -* ]]; then
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}));
        return 0;
    fi;
    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
}



case "$1" in
    import)
        info "Importing packages list"
        pacman_import
        exit $?
    ;;
    export)
        info "Exporting packages list"
        pacman_export
        exit $?
    ;;
    mvroot)
        if [ ! -n $2 ] || [ ! -n $3 ] \
        || [ ! -d $1 ] || [ ! -d $2] ; then
            error "Usage: $0 mvroot srcdir dstdir"
            exit 5
        fi
        info "Moving root filesystem"
        archlinux_mv_rootfs "$1" "$2"
        exit $?
    ;;
    *) printf "Usage: $0 import|export|mvroot <src> <dst>\n"
       exit 1
    ;;
esac

