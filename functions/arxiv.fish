
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

    # ls -l --color -t $HOME/Downloads/_arXiv
    # type -d detox && detox $HOME/Downloads/_arXiv/*
end


function __is_macOS
    if test (uname) = "Darwin" 
        return 0
    else
        return 1
    end
end
