
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
    
    echo "axs get -d $HOME/Downloads/_arXiv $ID; arxiv_bib $ID $HOME/Downloads/_arXiv/_cs_arxiv.bib"
    
    # ls -l --color -t $HOME/Downloads/_arXiv
    # type -d detox && detox $HOME/Downloads/_arXiv/*
end

