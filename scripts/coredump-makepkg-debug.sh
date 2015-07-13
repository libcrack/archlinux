#!/bin/bash
# dom abr 12 02:58:44 CEST 2015
# borja@libcrack.so

set -e

RED="\e[0;31m"
GREEN="\e[0;32m"
RESET="\e[0m"

coredir='/var/core'
corelist=$(ls ${coredir}/*.core | sort -u)
pkglist=()
exclude_pkglist=('skype' 'opera' 'imagemagick')
ABSROOT="${HOME}/repos/archlinux/abs"

echoerr(){
    /sbin/echo -e "${RED}>> ERROR:${RESET} ${*}"
}
echo(){
    /sbin/echo -e "${GREEN}>>${RESET} ${*}"
}

get_pkglist(){
    for core in ${corelist}; do
        bin="${core##*/}"
        bin="${bin%%.*}"
        pkg=$(pacman -Qqo --color=never "${bin}" 2>/dev/null) || {
            echoerr "Package owner of ${bin} ${RED}NOT FOUND${RESET}"
            continue
        }
        echo "Found binary ${bin} for coredump ${core}"
        echo "Found package ${pkg} for binary ${bin}"
        [[ "${pkglist[@]}" =~ "${pkg}" ]] || pkglist=(${pkglist[@]} "${pkg}")
    done
}

recompile_pkglist(){
    for pkg in ${pkglist[@]}; do
        [[ "${exclude_pkglist[@]}" =~ "${pkg}" ]] && {
            echo "Excluding package ${pkg}: listed in exclusions"
            continue
        }
        echo "Recompiling ${pkg}"
        pkgdir="$(find "${ABSROOT}" -type d -name "${pkg}")"
        [[ -d "${pkgdir}" ]] || {
            echo "Cannot find ${pkg} directory in ${ABSROOT}"
            pkgrepo="$(pacman -Si --color=never "${pkg}" | grep ^Repo)" || {
                echoerr "Cannot find ${pkg} repository"
                continue
            }
            pkgrepo="${pkgrepo##*: }"
            echo "Cloning ${ABSROOT}/${pkgrepo}/${pkg}"
            ABSROOT="${ABSROOT}" abs "${pkgrepo}/${pkg}"
            pkgdir="${ABSROOT}/${pkgrepo}/${pkg}"
        }
        echo "Moving into ${pkgdir}"
        cd "${pkgdir}"
        grep '^options=' PKGBUILD | grep -q 'debug' && {
            echo "Detected debug options in ${pkgdir}/PKGBUILD"
            pkg_inst_ver="$(pacman -Qi --color=never "${pkg}" | grep '^Versi' | sed 's/^Versi.n\s*:\s//')"
            pkg_repo_ver="$(pacman -Si --color=never "${pkg}" | grep '^Versi' | sed 's/^Versi.n\s*:\s//')"
            [[ "$pkg_inst_ver" == "$pkg_repo_ver" ]] && {
                echo "Skipping build of ${pkg}: debug package already installed"
                continue
            }
        } || {
            echo "Adding debug options to ${pkgdir}/PKGBUILD"
            /sbin/echo "options=('!strip' 'debug')" >> "${pkgdir}/PKGBUILD"
        }
        echo "Building packate ${pkg}"
        echo "----------------------------------------------------------------"
        makepkg --clean --syncdeps --noconfirm || echoerr "Failed to build package ${pkg}"
        echo "----------------------------------------------------------------"
    done
}

[[ -d "${coredir}" ]] || echoerr "Coredump dir ${coredir} not found"
[[ -d "${ABSROOT}" ]] || echoerr "ABS dir ${ABSROOT} not found"

echo "Analisying coredump from ${coredir}"

get_pkglist

echo "Packages to enable debug and recompile: ${pkglist[@]}"

recompile_pkglist

echo "Finished"

# /sbin/echo "pacman -S --color=never ${pkglist[@]}"
# pacman -S --color=never ${pkglist[@]}

