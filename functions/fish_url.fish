function fish_url --argument opt
    if test "$opt" = "";
        or test "$opt" = "help"
        echo "Usage: " 
        echo "    `fish_url help' to print this message"
        echo "    `fish_url init' to generate the necessary fish function and install it to conf.d"
        echo "    `set -Ux fish_url_hdl_config ~/.config/fish/fish_url_hdl.toml' --> the config file"
        echo 
        
        if not test -f ~/.config/fish/fish_url_hdl.toml 
            set -l _mydir  ( dirname (status -f) ) 
            mkdir -p ~/.config/fish/
            cp -iv $_mydir/config.toml ~/.config/fish/fish_url_hdl.toml 
        end

        return 0
    end
    
    if test "$opt" = "init"
        __init
    end
end


function __init 

    set _f0 ( mktemp /tmp/fish_hdl.XXXX )

    set _f ( mktemp /tmp/fish_hdl.XXXX )
    set _mydir  ( dirname (status -f) ) 

    set _utils_dir  $_mydir"/../utils"
    set _confd_dir  $_mydir"/../conf.d"
  
    # load necessary helper functions 
    source $_utils_dir/helper.fish

    
    echo "# "(date)                  > $_f0
    cat $_utils_dir/header.template >> $_f0  

    # Global variable to store the config file. If it's not defined, use the default file
    if set -q fish_url_hdl_config
        parse_simple_toml $fish_url_hdl_config > $_f
    else
        if not test -f  $_mydir/../config.toml 
            echo "No config file found"
            return 1
        end
        parse_simple_toml $_mydir/../config.toml  > $_f 
    end


    source $_f

    set keys ( cat $_f | awk '{print $2}' | awk -F_ '{print $1}' | uniq )
    # echo $keys

    set full_keys ( cat $_f | awk '{print $2}' )
    # echo $full_keys

    # input the array as a single string
    set file_ext_keys ( __subset_keys "$full_keys" __extension )
    set url_keys ( __subset_keys "$full_keys" __url )
    set file_cmd_keys ( __subset_keys "$full_keys" __FILE__command )
    set url_cmd_keys ( __subset_keys "$full_keys" __URL_command )

    #
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
            | grep -v ^\#             \
            | string replace -a __CMDLINE__  "$cmd"  \
            | string replace -a __INPUT__  '$INPUT'  \
            | string replace __FILE_EXT_FUNC__  __"$i"  >> $_f0

    end


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
            | grep -v ^\#         \
            | string replace -a __CMDLINE__  "$cmd" \
            | string replace -a __INPUT__  '$INPUT' \
            | string replace __URL_FUNC__  __"$i"  >> $_f0

    end

    cp -f $_f0  $_confd_dir/fish_url_hdl.fish

    echo "Initialization completed successfully. Check "$_confd_dir/fish_url_hdl.fish
    rm -f $_f0
    rm -f $_f

end


# ------------- Private Func -----------------------------

function __subset_keys 

    set fullk ( echo $argv[1] | string split ' ' )
    set patt $argv[2]

    for i in $fullk
        echo $i | string match -q "*$patt*" && set -a subset $i
    end

    echo  $subset
end
