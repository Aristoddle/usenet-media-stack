#!/bin/bash
# Bash completion for usenet command

_usenet_completions() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    commands="setup manage test validate creds backup restore update help"
    
    # Sub-commands for each main command
    local setup_opts="--test-only --skip-test --verbose --help"
    local manage_cmds="start stop restart status logs backup restore update clean"
    local test_types="quick essential full all"
    
    case "${COMP_CWORD}" in
        1)
            # Complete main commands
            COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
            ;;
        2)
            # Complete based on main command
            case "${prev}" in
                setup|deploy)
                    COMPREPLY=($(compgen -W "${setup_opts}" -- "${cur}"))
                    ;;
                manage|mgmt)
                    COMPREPLY=($(compgen -W "${manage_cmds}" -- "${cur}"))
                    ;;
                test)
                    COMPREPLY=($(compgen -W "${test_types}" -- "${cur}"))
                    ;;
                backup|restore)
                    # File completion for backup/restore
                    COMPREPLY=($(compgen -f -- "${cur}"))
                    ;;
            esac
            ;;
        3)
            # Complete service names for manage commands
            if [[ "${COMP_WORDS[1]}" == "manage" || "${COMP_WORDS[1]}" == "mgmt" ]]; then
                local services="all sabnzbd prowlarr sonarr radarr readarr mylar3 bazarr jellyfin overseerr"
                case "${prev}" in
                    logs|restart|stop|start)
                        COMPREPLY=($(compgen -W "${services}" -- "${cur}"))
                        ;;
                esac
            fi
            ;;
    esac
    
    return 0
}

# Register the completion function
complete -F _usenet_completions usenet

# Also support if installed in PATH as 'usenet'
complete -F _usenet_completions ./usenet