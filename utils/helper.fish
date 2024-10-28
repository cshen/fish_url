

functions --query parse_simple_toml  && exit 0 # Do not source twice


function canonicalize
    cd "$argv[1]" || return
    pwd
end

function read_confirm
    while true
        echo "$argv[1]"
        read -p ' echo "      Confirm? (y/[n]): " ' -l confirm

        switch $confirm
            case Y y
                return 0
            case '' ' ' N n
                return 1
        end
    end
end

function ext_name
    #Usage: ext_name "path"

    if not echo "$argv[1]" | grep -q '\.'
        echo ""
        return 1
    end

    echo "$argv[1]" | rev | cut -d '.' -f 1 | rev | string lower
    return 0
end

# 
# yet another impl of getting ext
# CS: Sep 2024
function ext_name2

    if not echo "$argv[1]" | grep -q '\.'
        echo ""
        return 1
    end

    set filename $argv[1]
    set extension (string split '.' $filename)[-1]
    echo $extension
end


function remove_ext_name
    echo "$argv[1]" | rev | cut -d '.' -f2- | rev | string lower
end


# "xxxx" ---> xxxx
# 'xxxx' ---> xxxx
# "xxxx' ---> xxxx
# https://stackoverflow.com/questions/66285878/in-fish-shell-why-cant-one-functions-output-pipe-to-another CS: 25 Oct 2024 12:00
# https://github.com/fish-shell/fish-shell/issues/206 
function string_remove_quote --argument input

    if isatty stdin
        set s "$input"
    else
        read s  
        # pipe input
    end

    # Cannot pipe results into __remove_first 
    __remove_first ( __remove_first $s | rev ) | rev
end


function file_exist
    test -f $argv[1] && return 0 || return 1
end

function command_exist
    type -q $argv[1] 2>/dev/null && return 0 || return 1
end

function load_if_exist
    if test -f $argv[1]
        source $argv[1]
    end
end

function is_macOS
    set --local _x (__os)
    test $_x = macos && return 0 || return 1
end

function is_Linux
    set --local _x (__os)
    test $_x = linux && return 0 || return 1
end

function is_WSL
    is_Linux || return 1
    grep -q -i Microsoft /proc/version && return 0 || return 1
end

# MSYS2 under Winodws
function is_MINGW
    return ( string match -q 'MINGW*' "$(uname)" )
end

# Test if an input argument is a symlink
function is_symlink --argument file
    test -L (echo $file  | string replace -r '/$' '')
end

function is_string_empty --argument str
    string length --quiet "$str" && return 1 || return 0
end

function is_valid_string --argument str
    string length --quiet "$str" && return 0 || return 1
end


function set_val_or_default --argument val default

    if not is_string_empty $val
        echo $val
    else
        echo $default
    end
end


function clean_config --argument filename -d "Clean up a config file by removing blank lines and comments. For now, comments starts with #"

    set lines (cat $filename)
    for line in $lines
        set -l x ( string trim $line  )

        set -l first $( echo $x | string sub -s 1 -e 1 )

        # remove blank and comments
        if  test "$x" = ""
            or  test "$first" = '#' 
            # pass 
        else 
            set -a newlines ( echo  $x | awk -F\# '{ print $1}'  )    # remove comments
        end
    end

    # fish is not able to return a list/array directory
    # We need to pack the array into one string, with \n as the delimit
    printf %s\n $newlines  | string join -- \n

end

# This is a TOML document
# title = "TOML Example"
# [owner]
# name = "Tom Preston-Werner"
# dob = 1979-05-27T07:32:00-08:00
# [database]
# enabled = true
# ports = [ 8000, 8001, 8002 ]
# data = [ "delta" ]
# temp_targets = { cpu = 79.5 }
function __fishurl_parse_simple_toml --argument input_file --d "Parse simple TOML config into Fish source-able text"

    set newlines ( clean_config $input_file )

    # extract sections in [xxxx]
    for s in ( printf %s\n $newlines | grep  '^\['  )
        set -a sections ( echo $s | awk -F\[ '{print $2}' | awk -F\] '{print $1}' )
    end

    for l in $newlines
        if echo $l | string match -q "[*]"  
            set s ( echo $l | awk -F\[ '{print $2}' | awk -F\] '{print $1}' ) 
            #    echo $s
        else

            set key ( echo $l | awk -F= '{print $1}' | string trim )
            set val ( echo $l | cut -d "=" -f2- | string trim | string unescape )

            # CS: 29 Oct 2024 09:48 
            # Only for this project, I inject a special text here, to avoid potential name collision
            # echo "set  " $s"__"$key  ' '\"$val\"  
            echo "set  " $s"_CSFISHURL__"$key  ' '\"$val\"  

        end
    end
end


#---- Private functions --------------------
function __os

    switch (uname)
        case Linux
            echo linux
        case Darwin
            echo macos
        case FreeBSD NetBSD DragonFly
            echo bsd
        case '*'
            echo unknown
    end
end

function __remove_first --argument input
    # first char

    set s "$input"

    set first $( echo $s | string trim | string sub -s 1 -e 1 )

    if test $first = "\""
        or test $first = "'"
        echo $s | cut -c2-
    else
        echo $s
    end
    return 0
end

# vim: ft=fish 
# CS: 25 Oct 2024 13:44 
