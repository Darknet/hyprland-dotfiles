function fish_prompt
    # Guardar el estado del último comando
    set -l last_status $status
    
    # Colores Catppuccin Mocha
    set -l color_cwd 89b4fa
    set -l color_git f9e2af
    set -l color_error f38ba8
    set -l color_success a6e3a1
    set -l color_user cba6f7
    set -l color_host 94e2d5
    set -l color_normal cdd6f4
    
    # Usuario y host
    set_color $color_user
    echo -n (whoami)
    set_color $color_normal
    echo -n "@"
    set_color $color_host
    echo -n (hostname)
    set_color $color_normal
    echo -n ":"
    
    # Directorio actual
    set_color $color_cwd
    echo -n (prompt_pwd)
    
    # Información de Git
    if git rev-parse --git-dir >/dev/null 2>&1
        set -l git_branch (git branch --show-current 2>/dev/null)
        if test -n "$git_branch"
            set_color $color_normal
            echo -n " ("
            set_color $color_git
            echo -n "$git_branch"
            
            # Estado del repositorio
            if not git diff-index --quiet HEAD -- 2>/dev/null
                set_color $color_error
                echo -n "*"
            end
            
            set_color $color_normal
            echo -n ")"
        end
    end
    
    # Prompt final con color según el estado
    set_color $color_normal
    echo -n " "
    if test $last_status -eq 0
        set_color $color_success
        echo -n "➜"
    else
        set_color $color_error
        echo -n "✗"
    end
    set_color $color_normal
    echo -n " "
end
