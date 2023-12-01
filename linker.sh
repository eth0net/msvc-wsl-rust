#!/bin/bash

script_path="$(dirname "${BASH_SOURCE[0]}")"
source "$script_path/config.sh"

host=x64
target=${TARGET_ARCH:=x64}

# shellcheck disable=SC2154
if [ "$vs_version" == 2022 ]; then
  msvc_path=${MSVC_PATH:="C:\\Program Files\\Microsoft Visual Studio\\$vs_version\\Community\\VC\\Tools\\MSVC"}
else
  msvc_path=${MSVC_PATH:="C:\\Program Files (x86)\\Microsoft Visual Studio\\$vs_version\\BuildTools\\VC\\Tools\\MSVC"}
fi

# shellcheck disable=SC2154
tools_path="$msvc_path\\$tools_version"
linker_exec="$tools_path\\bin\\Host$host\\$target\\link.exe"
crt_libs="$tools_path\\lib\\$target\\"

# shellcheck disable=SC2154
sdk_path="C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\$sdk_version"
sdk_libs="$sdk_path\\um\\$target\\"
ucrt_libs="$sdk_path\\ucrt\\$target\\"

echo "\$env:LIB=\"$sdk_libs;$ucrt_libs;$crt_libs\"" > "$script_path/last-linking.ps1"

path_from_windows()
{
        # shellcheck disable=SC2154
        echo "\\\\wsl\$\\$wsl_distro$(echo "$1" | sed "s/\//\\\\/g")"
}

args=""

for v in "$@"; do
        num_of_slash=$(tr -dc '/' <<< "$v" | wc -c)
        num_of_colon=$(tr -dc ':' <<< "$v" | wc -c)
        if [ "$num_of_slash" -gt "1" ] && [ "$num_of_colon" -eq "0" ]; then
                v="$(path_from_windows "$v")"
        fi
        if [ "$num_of_slash" -gt "1" ] && [ "$num_of_colon" -eq "1" ]; then
                v1="$(echo "$v" | cut -d ':' -f 1)"
                v2="$(echo "$v" | cut -d ':' -f 2)"
                v2="$(path_from_windows "$v2")"
                v="$v1:$v2"
        fi
        args="$args $v"
done

log_file="$(path_from_windows "$script_path/last-linking.log")"

commands_file="$(path_from_windows "$script_path/last-linking-args.txt")"

echo "$args" > "$script_path/last-linking-args.txt"

echo "& \"$linker_exec\" \"@$commands_file\" | Out-file \"$log_file\"" >> "$script_path/last-linking.ps1"

powershell.exe -Command "$script_path/last-linking.ps1"
