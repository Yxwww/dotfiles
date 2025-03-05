encrypt() {
  tar --create --file - --gzip -- "$@" |
    open ssl aes-256-cbc -salt -out out.enc
}

decrypt() {
  openssl aes-256-cbc -d -salt -in "$1" |
    tar -v --extract --gzip --file -
}
. "$HOME/.cargo/env"
# . "/Users/yuxiwang/.deno/env"

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
