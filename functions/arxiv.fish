
function arxiv -d "downalod arxiv papers. `axs' is needed."

    # extract arxiv id
    # https://arxiv.org/pdf/2410.00890
    # https://arxiv.org/abs/2410.00890
    set -l ID $( echo $argv | rev | awk -F/ '{print $1}' | rev )

    # When the URL is quoted with " or ', the above will have " or ' at the tail, remove it
    set -l ID $( echo $ID | sed 's/"//g' | sed 's/\'//g' )  
    
    mkdir -p $HOME/Downloads/_arXiv

    # using axs to download. 
    # Install:  pipx install git+https://github.com/cshen/arxiv_download   
   
    if __command_exist axs

        echo "command: axs get -d $HOME/Downloads/_arXiv $ID"

        if __is_macOS 
            set fn ( axs get -d $HOME/Downloads/_arXiv $ID | grep -i "Article saved" |  \
                rev | awk -F/ '{print $1}'| rev | awk -F. '{print $1}' )

            echo The downloaded file is $fn.pdf in $HOME/Downloads/_arXiv \(file path is copied to clipboard\) 
            echo $HOME/Downloads/_arXiv/$fn.pdf | pbcopy  
        else
            axs get -d $HOME/Downloads/_arXiv $ID  
        end


        arxiv_bib $ID $HOME/Downloads/_arXiv/_cs_arxiv.bib


        return $status
        # ls -l --color -t $HOME/Downloads/_arXiv
        # type -d detox && detox $HOME/Downloads/_arXiv/*
    else

        __download $argv $HOME/Downloads/_arXiv
        return $status 
    end

end



# ----------------------------------------------------------------------
function __download --argument input output_dir

    
    test "$output_dir" = "" && set output_dir $HOME/Downloads/

    set arx_url ( __arxiv_link $input )
    if not test "$arx_url" = "" 
        set input $arx_url
        echo arxiv PDF link is: $input
    end  
    
    if __command_exist wget
        wget -c -P $output_dir  $input
        return $status
    end

    if __command_exist curl 
        curl -L --output-dir  $output_dir -O  $input
        return $status
    end

end


function __command_exist
    type -q $argv[1] 2>/dev/null && return 0 || return 1
end

function __arxiv_link 

    if echo $argv | grep -i -q 'arxiv.org'   
        #  https://arxiv.org/pdf/2410.00890 
        set -l ID $( echo $argv | rev | awk -F/ '{print $1}' | rev )
        echo ( string escape -- https://arxiv.org/pdf/$ID'.pdf' )
    else
        echo ""
    end

end


function __is_macOS
    if test (uname) = "Darwin" 
        return 0
    else
        return 1
    end
end
