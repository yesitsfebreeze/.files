# Shared cockpit store for bash and zsh. Values are data, never shell code.
_dotfiles_load_env() {
    local _kept_store="${XDG_STATE_HOME:-$HOME/.local/state}/env/vars"
    local _kept_row _kept_key
    [ -r "$_kept_store" ] || return 0
    while IFS= read -r _kept_row || [ -n "$_kept_row" ]; do
        case $_kept_row in
            *=*) _kept_key=${_kept_row%%=*} ;;
            *) continue ;;
        esac
        case $_kept_key in
            ''|[0-9]*|*[!a-zA-Z0-9_]*) continue ;;
        esac
        export "$_kept_key=${_kept_row#*=}"
    done < "$_kept_store"
}
_dotfiles_load_env
unset -f _dotfiles_load_env
