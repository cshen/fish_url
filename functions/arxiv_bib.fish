
function arxiv_bib -a 'arxiv_id'  -a 'bibtex_file' --description "Extract bibtex information from arXiv using axs"
    
    set -l bib $( axs bib $arxiv_id )
    set -l entry $( echo $bib[1] | grep -i  @article | awk -F\{ '{print $2}' |sed 's/,//' )


    if  not test -n "$bibtex_file"; or  not test -f "$bibtex_file"
        for i in $bib
            string length --quiet $i && echo $i
        end
        echo "bibtex information was not written to bibtex file"
        return 1
    end

    if cat $bibtex_file | grep -q "$entry"

        echo "bib entry $entry is already in the file"

    else
        for i in $bib
            string length --quiet $i && echo $i >>$bibtex_file
        end
        echo "" >> $bibtex_file
        echo "Done writing to the bibtex file"
    end

end
