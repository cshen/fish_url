function fish_url --argument opt
    if test "$opt" = "";
        or test "$opt" = "help"
        echo "Usage: " 
        echo "    `fish_url help' to print this message"
        echo "    `fish_url init' to generate the necessary fish function and install it to conf.d"
        echo "    `set -gx fish_url_hdl_config ~/.config/fish/fish_url_config.toml', to define your own config file in config.fish"
        echo 
        
        __copy_config 

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

        if not test -f $fish_url_hdl_config
            echo "$fish_url_hdl_config not found! However, \$fish_url_hdl_config is defined as:"
            echo "    $fish_url_hdl_config" 
            return 1
        end
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
    
    # parse_simple_toml config.toml    to check the results: e.g.,
    # ---> set   PDF_FishHDL_FILE__extension  "pdf|PDF"
    # ---> set   PDF_FishHDL_FILE__command  "pdfly.sh __INPUT__" 
    # ---> set   Convertimages_FishHDL_Generic__rule  ".*convert.*image.*"
    # ---> set   Convertimages_FishHDL_Generic__command  "tldr magick"
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

    set -l config_dir  ~/.config/fish/   
    set -l _mydir  ( dirname (status -f) ) 

    if bash -c 'ls ~/.config/fish/fish_url*.toml  &>  /dev/null'  
        # skip
    else
        mkdir -p $config_dir 
        cp -iv $_mydir/../config.toml $config_dir/fish_url_config.toml
    end
end

