export EDITOR=micro

alias mup='env MISE_PREFER_OFFLINE=false mise up --minimum-release-age=0s'

## https://mise.jdx.dev/ide-integration.html#ide-integration
eval "$(mise activate ${SHELL##*/})"
