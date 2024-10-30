function fix_file_not_run --on-event fish_postexec
    
    
    # post processing goes here
    # If a command is not found, the child process created to execute it returns a status of 127. 
    # If a command is found but is not executable, the return status is 126.
    if test $status = 126
        
        set cmdline (echo $argv | string trim)
        # if it's a text file, using gvim to open it
        # Otherwise try to open it

        # tell if it's a text file
        if file  $cmdline   | grep -i -q 'ascii text'
            echo it apperas to be a text file, and show the first a few lines
            
            set -q EDITOR && $EDITOR $cmdline || cat  $cmdline | head -10
            
        else
            echo it appears to be a file, and try to open it
          
            test -x /usr/bin/open && /usr/bin/open $cmdline 
        
        end
    end
end

