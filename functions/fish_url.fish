function fish_url --argument opt

    set VER 0.1.1

    if test "$opt" = "help"
        echo "Usage: "
        echo "    `fish_url help' to print this message"
        echo "    `fish_url init (-f)' to generate the necessary fish abbr function and install it to conf.d"
        echo "                    with -f, the abbr func is always re-generated. without -f, if the file already exisits, it will do nothing. "
        echo "    `fish_url env' to show the environment variables currently used"
        echo "    `set -gx fish_url_hdl_config ~/.config/fish/fish_url_config.toml', to define your own config file in config.fish"
        echo 
        
        __copy_config 

        return 0
    end
    
    if test "$opt" = "version"
        echo fish_url version: $VER 
        return 0
    end

    if test "$opt" = "env"
        set -q fish_url_hdl_config && echo  \$fish_url_hdl_config"  "$fish_url_hdl_config || echo  \$fish_url_hdl_config is not set
        status features | grep -i qmark-noglob          
        return 0
    end

    if test "$opt" = "init"
        __fishurl_init  "$argv[2]"
       return 0
    end

    echo "Usage: "
    echo "    `fish_url (init | version | env | help)'"
    
end




function __fishurl_init --argument force


    set _mydir  ( dirname (status -f) ) 
    set _utils_dir  $_mydir"/../utils"
    set _confd_dir  $_mydir"/../conf.d"
  
    # if it's not forced to init, and the abbr file is already there, abort
    if not test "$force" = "-f";
        and test -f  $_confd_dir/fish_url_hdl.fish
        return 0
    end


    set _f0 ( mktemp /tmp/fish_hdl.XXXX )
    set _f ( mktemp /tmp/fish_hdl.XXXX )


    # Not needed anymore
    # load necessary helper functions 
    # source $_utils_dir/helper.fish

    echo "# "(date)                  > $_f0
    cat $_utils_dir/header.template >> $_f0  

    # Global variable to store the config file. If it's not defined, use the default file
    # Parse the config file
    if set -q fish_url_hdl_config

        if not test -f $fish_url_hdl_config
            echo "$fish_url_hdl_config not found! However, \$fish_url_hdl_config is defined as:"
            echo "    $fish_url_hdl_config. Fall back to the default config file"  
            __fishurl_parse_simple_toml $_mydir/../config.toml > $_f || return 1
        else
            __fishurl_parse_simple_toml $fish_url_hdl_config > $_f   || return 1
        end
    else
        if not test -f  $_mydir/../config.toml 
            echo "No config file found"
            return 1
        end
        __fishurl_parse_simple_toml $_mydir/../config.toml  > $_f || return 1
    end

    source $_f



    set keys ( cat $_f | awk '{print $2}' | awk -F_ '{print $1}' | uniq )
    # echo $keys

    set full_keys ( cat $_f | awk '{print $2}' )
    # echo $full_keys
    
    # __fishurl_parse_simple_toml config.toml    to check the results: e.g.,
    # ---> set   PDF_FILE__extension  "pdf|PDF"
    # ---> set   PDF_FILE__command  "pdfly.sh __INPUT__" 
    # ---> set   Convertimages_Generic__rule  ".*convert.*image.*"
    # ---> set   Convertimages_Generic__command  "tldr magick"
    #  
    # input the array as a single string
    set file_ext_keys ( __subset_keys "$full_keys" __extension )
    set url_keys ( __subset_keys "$full_keys" __url )
    set generic_keys ( __subset_keys "$full_keys" __rule )

    # The following 3 variables are not used in the code. I just keep them for debugging CS: 28 Oct 2024 21:27 
    set file_cmd_keys ( __subset_keys "$full_keys" _FILE__command )
    set url_cmd_keys ( __subset_keys "$full_keys" _URL__command )
    set generic_cmd_keys ( __subset_keys "$full_keys" _Generic__command )
   
    
    # 1. ------------------------------------------------
    # File extension processing
    # $$x ---> get the value of $( $x ) where ($x) is the value of $x
    for i in ( echo $file_ext_keys | string split ' ' ) 

        # abbr -a img_file --position command --regex ".+\.(png|PNG|HEIC|heic)\"?\'?" --function _img_file
        # echo "abbr -a _$i --position command --regex"  \".+\\.\((  echo $$i   )\)\\\"?\\\'?\"    "--function __$i" >> $_f0
        #
        # get the cmd_val from the full key $i
        set -l x ( echo $i | awk -F__ '{print $1}' )
        # the command will be $x__command
        set -l z ( echo $x"__command" ) 
        set cmd ( echo $$z )
        # need to pass $cmd to the function

        echo "abbr -a _$i --position command --regex"  \".+\\.\((  echo $$i   )\)\\\"?\\\'?\"    "--function __$i"  >> $_f0 

        echo " "    >> $_f0


        # echo $i

        cat $_utils_dir/file_ext.template \
            | grep -v ^\#                 \
            | string replace -a __CMDLINE__  "$cmd"  \
            | string replace -a __INPUT__  '$INPUT'  \
            | string replace __FILE_EXT_FUNC__  __"$i"  >> $_f0

    end

    # 2. ------------------------------------------------
    set -e i x z
    # -------- https URL processing --------------------- 
    for i in ( echo $url_keys | string split ' ' ) 
        set -l x ( echo $i | awk -F__ '{print $1}' )
        # the command will be $x__command
        set -l z ( echo $x"__command" ) 
        set cmd ( echo $$z )

        # abbr -a arxiv_download --position command --regex "\"?\'?https:\/\/arxiv.*" --function _arxiv_download
        echo "abbr -a _$i --position command --regex"  \"\\\"?\\\'?( echo $$i )".*"\"   "--function __$i"  \
            >> $_f0 

        echo " "    >> $_f0

        # echo $i

        cat $_utils_dir/url.template  \
            | grep -v ^\#             \
            | string replace -a __CMDLINE__  "$cmd" \
            | string replace -a __INPUT__  '$INPUT' \
            | string replace __URL_FUNC__  __"$i"  >> $_f0

    end

    # 3. ------------------------------------------------
    set -e i x z
    # -------- Generic rule processing ------------------ 
    for i in ( echo $generic_keys | string split ' ' ) 
        set -l x ( echo $i | awk -F__ '{print $1}' )
        # the command will be $x__command
        set -l z ( echo $x"__command" ) 
        set cmd ( echo $$z )
        
        echo "abbr -a _$i --position command --regex"   ( echo $$i | string escape )  "--function __$i"  \
            >> $_f0 

        echo " "    >> $_f0
        
        cat $_utils_dir/generic.template  \
            | grep -v ^\#                 \
            | string replace -a __CMDLINE__  "$cmd" \
            | string replace -a __INPUT__  '$INPUT' \
            | string replace __GENERIC_FUNC__  __"$i"  >> $_f0
    end
    # end processing ------------------------------------
    


    cp -f $_f0  $_confd_dir/fish_url_hdl.fish

    echo "Initialization completed successfully. Check "(realpath $_confd_dir)"/fish_url_hdl.fish"
    rm -f $_f0
    rm -f $_f

    return 0
end





# ------------- Private Func ----------------------------

function __subset_keys 

    set fullk ( echo $argv[1] | string split ' ' )
    set patt $argv[2]

    for i in $fullk
        echo $i | string match -q "*$patt*" && set -a subset $i
    end

    echo  $subset
end


function __copy_config

    set -l config_dir  ~/.config/fish  
    set -l _mydir  ( dirname (status -f) ) 

    if bash -c 'ls ~/.config/fish/fish_url*.toml  &>  /dev/null'  
        # skip
    else
        mkdir -p $config_dir 
        echo "Config file copied to your ~/.config/fish/ directory:"
        cp -iv $_mydir/../config.toml $config_dir/fish_url_config.toml
    end
end


function __fishurl_parse_simple_toml --argument input_file --d "Parse simple TOML config into Fish source-able text"


    if not test -f $input_file 
        echo "$input_file not found" 
        return 1
    end

    set newlines ( __clean_config $input_file )

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



function __clean_config --argument filename -d "Clean up a config file by removing blank lines and comments. For now, comments starts with #"

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

