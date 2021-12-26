encrypt() {
  tar --create --file - --gzip -- "$@" | \
  open ssl aes-256-cbc -salt -out out.enc
}

decrypt() {
  openssl aes-256-cbc -d -salt -in "$1" | \
  tar -v --extract --gzip --file -
}
. "$HOME/.cargo/env"
