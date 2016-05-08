#!/bin/bash
# borja@libcrack.so
# vie ago  1 01:37:56 CEST 2014

username='xxxxx'
password='yyyyy'

cwd="$PWD"

which burp namcap mkaurball > /dev/null || exit "$?"

test -z "$1" && {
    echo -e "\n\tUsage: $0 <pkg_dir | pkg_dirs.txt>\n"
    echo -e "\t$0 fuzz-taviso"
    echo -e "\t$0 packages.list\n"
    exit 1
}

build(){
    local pkgdir="$1"
    cd "$pkgdir"
    echo "[*] Building package $pkgdir"
    rm *.src.tar.gz
    namcap PKGBUILD
    mkaurball
    cd -
}

upload(){
    local pkgsrc=$(find "$1" -name "*.src.tar.gz" -print0)
    echo "[*] Uploading $pkgsrc to AUR"
    burp -u "$username" -p "$password" "$pkgsrc"
}

ftype=$(file -b "$1" | awk '{print $1}')

case "$ftype" in
    directory)
        build "$1"
        upload "$1"
        ;;
    ASCII)
        echo "[*] Reading directory list $1"
        while read pkgdir; do
            build "$pkgdir"
            upload "$pkgdir"
        done < "$1"
        ;;
    *)
        echo "ERROR: The argument is neither a directory or a directory list"
        ;;
esac

exit $?
