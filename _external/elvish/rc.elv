use re
use str
use path
use os

# PATH
fn add_to_path {
  |@my_paths|  
  each {
    |my_path|
    if (not (has-value [(each {|p| ==s $my_path $p} $paths)] 0)) {
      set paths = [$my_path $@paths]
    }
  } $my_paths
}

var cargo_path = (path:clean (path:join $E:HOME .cargo bin))
var ghcup_path = (path:clean (path:join $E:HOME .ghcup bin))
var cabal_path = (path:clean (path:join $E:HOME .cabal bin))
var go_path = (path:clean (path:join $E:HOME .local share go bin))
var local_bin  = (path:clean (path:join $E:HOME .local bin))
var site_perl = "/usr/bin/site_perl"
var vendor_perl = "/usr/bin/vendor_perl"
var core_perl = "/usr/bin/core_perl"
add_to_path $cargo_path $ghcup_path $cabal_path $go_path $local_bin $site_perl $vendor_perl $core_perl

if (has-external "/opt/homebrew/bin/brew") {
  add_to_path (/opt/homebrew/bin/brew --prefix)"/bin"
}

if (has-external carapace) {
  eval (e:carapace _carapace | slurp)
}

if (has-external helix) {
  set-env EDITOR "helix"
  set-env VISUAL "helix"
} elif (has-external hx) {
  set-env EDITOR "hx"
  set-env VISUAL "hx"
} elif (has-external nvim) {
  set-env EDITOR "nvim"
  set-env VISUAL "nvim"
} else {
  set-env EDITOR "vim"
  set-env VISUAL "vim"
}

set-env PAGER "less"
if (has-external bat) {
  set-env PAGER "bat --chop-long-lines"
  set-env MANPAGER "bat --chop-long-lines -p"
}
fn bat {|@all| e:bat --chop-long-lines $@all }
fn batp {|@all| e:bat --chop-long-lines -p $@all }
set edit:completion:arg-completer[batp] = $edit:completion:arg-completer[bat]

if (not (has-env XDG_CONFIG_HOME)) {
  set-env XDG_CONFIG_HOME (path:join $E:HOME .config)
}

if (not (has-env XDG_DATA_HOME)) {
  set-env XDG_DATA_HOME (path:join $E:HOME .local share)
}

if (not (has-env XDG_CACHE_HOME)) {
  set-env XDG_CACHE_HOME (path:join $E:HOME .cache)
}

if (not (has-env XDG_RUNTIME_DIR)) {
  set-env XDG_RUNTIME_DIR (path:join $path:separator run user $E:EUID)
}

if (has-external "/Applications/Firefox.app/Contents/MacOS/firefox") {
  set-env BROWSER "/Applications/Firefox.app/Contents/MacOS/firefox"
} else {
  set-env BROWSER "firefox"
}

set-env LESSHISTFILE "-"
set-env WINEPREFIX (path:join $E:XDG_DATA_HOME wineprefixes default)
set-env PASSWORD_STORE_DIR (path:join $E:XDG_DATA_HOME password-store)
set-env GOPATH (path:join $E:XDG_DATA_HOME go)
set-env WEECHAT_HOME (path:join $E:XDG_DATA_HOME weechat)
set-env GNUPGHOME (path:join $E:XDG_DATA_HOME gnupg)
set-env NOTMUCH_CONFIG (path:join $E:XDG_CONFIG_HOME notmuch config)
set-env OBJC_DISABLE_INITIALIZE_FORK_SAFETY "YES"

# Locale
set-env LC_ALL "en_US.UTF-8"

fn upgrade {
  if (has-external rustup) {
    rustup update
  }

  if (has-external cargo-install-update) {
    cargo install-update --all
  }

  if (has-external pipx) {
    pipx upgrade-all
  }
}

# ALIASES

if (and (os:exists ~/.config/aria2/aria2d.env) (os:is-regular ~/.config/aria2/aria2d.env) (not (os:is-dir ~/.config/aria2/aria2d.env))) {
  from-lines < ~/.config/aria2/aria2d.env | peach {
    |line|

    if ?(grep -q '^#' (slurp < $line)) {
      break
    }

    var fields = [(str:split "=" $line)]
    if (== (count $fields) 2) {
      echo "set-env "$fields[0]" "$fields[1] | eval (slurp)
    }
  }
}

fn aria2p  {|@a| e:aria2p --secret=$E:ARIA2_RPC_TOKEN $@a }

fn icat {|@rest| e:kitty +kitten icat $@rest}
fn kdiff {|@rest| e:kitty +kitten diff $@rest}

fn vim {|@a| e:vim $@a}
fn vimdiff {|@a| e:vim -d $@a}

if (has-external nvim) {
  set edit:completion:arg-completer[vim] = $edit:completion:arg-completer[nvim]
  set vim~ = {|@a| e:nvim $@a}
  set vimdiff~ = {|@a| e:nvim -d $@a}
}

fn mutt {|@a| e:mutt $@a}
fn em {|@a| e:mutt $@a}

if (has-external neomutt) {
  set edit:completion:arg-completer[mutt] = $edit:completion:arg-completer[neomutt]
  set edit:completion:arg-completer[em] = $edit:completion:arg-completer[neomutt]
  set mutt~ =  {|@a| e:neomutt $@a}
  set em~ = {|@a| e:neomutt $@a}
} 

# Standard utils with better options
set edit:completion:arg-completer[mkd] = $edit:completion:arg-completer[mkdir]
fn mkd {|@a| e:mkdir -pv $@a}

set edit:completion:arg-completer[s] = $edit:completion:arg-completer[sed]
fn s {|@a| e:sed --posix $@a}

set edit:completion:arg-completer[G] = $edit:completion:arg-completer[grep]
fn G {|@a| e:grep --color=auto $@a}

set edit:completion:arg-completer[a] = $edit:completion:arg-completer[awk]
fn a {|@a| e:awk $@a}

fn df {|@a| e:df $@a}
fn mv {|@a| e:mv -iv $@a}
fn cp {|@a| e:cp -iv $@a}
fn du {|@a| e:du -h $@a}
fn ed {|@a| e:ed -vp '*' $@a}
fn diff {|@a| e:diff --color=auto $@a}

# Programs with specific options
set edit:completion:arg-completer[sysu] = $edit:completion:arg-completer[systemctl]
fn sysu {|@a| systemctl --user $@a }

set edit:completion:arg-completer[k] = $edit:completion:arg-completer[make]
set edit:completion:arg-completer[kd] = $edit:completion:arg-completer[make]
fn k {|@rest| e:make -j4 $@rest}
fn kd {|@rest| e:make DEBUG=yes -j4 $@rest}

if (has-external nproc) {
  set k~ = {|@rest| e:make -j(e:nproc) $@rest}
  set kd~ = {|@rest| e:make DEBUG=yes -j(e:nproc) $@rest}
}

set edit:completion:arg-completer[mpvf] = $edit:completion:arg-completer[mpv]
set edit:completion:arg-completer[anipv] = $edit:completion:arg-completer[mpv]
set edit:completion:arg-completer[termpv] = $edit:completion:arg-completer[mpv]
fn mpvf {|@a| mpv --fs $@a }
fn anipv {|@a| mpv --slang=en,eng --fs --alang=jpn,jp $@a }
fn termpv {|@a| mpv --vo=kitty --vo-kitty-use-shm=yes $@a }

set edit:completion:arg-completer[rfcdate] = $edit:completion:arg-completer[date]
set edit:completion:arg-completer[emdate] = $edit:completion:arg-completer[date]
fn rfcdate {|@a| date --iso-8601="seconds" $@a }
fn emdate {|@a| date -R $@a }
fn xz {|@a| e:xz --threads=0 $@a }

fn ssh {|@rest| e:ssh -o 'VisualHostKey=yes' $@rest}

if (has-external kitty) {
  set ssh~ = {|@rest| e:kitty +kitten ssh -o "VisualHostKey=yes" $@rest}
}

set edit:completion:arg-completer[ydl] = $edit:completion:arg-completer[yt-dlp]
fn ydl {|@a| yt-dlp -ic -o '%(title)s.%(ext)s' --add-metadata --user-agent 'Mozilla/5.0 (compatible; Googlebot/2.1;+http://www.google.com/bot.html/)' $@a }

fn ls {|@a| e:ls --color=auto -F -H -h $@a }

set edit:completion:arg-completer[ll] = $edit:completion:arg-completer[ls]
set edit:completion:arg-completer[la] = $edit:completion:arg-completer[ls]
fn ll {|@a| e:ls --color=auto -l -F -H -h $@a }
fn la {|@a| e:ls --color=auto -F -H -h -A $@a }

set edit:completion:arg-completer[exal] = $edit:completion:arg-completer[exa]
set edit:completion:arg-completer[exat] = $edit:completion:arg-completer[exa]
fn exal {|@a| e:exa -lhb $@a }
fn exa {|@a| e:exa --icons $@a }
fn exat {|@a| e:exa --tree -lbh $@a }

fn tract {|@a| transmission-remote -F '~l:done' $@a }
# fn tract_complete {|@a| $edit:completion:arg-completer[transmission-remote] transmission-remote -F '~l:done' $@a }
# set edit:completion:arg-completer[tract] = $tract_complete~

# Shortening names
fn trem {|@a| transmission-remote $@a}
# set edit:completion:arg-completer[trem] = $edit:completion:arg-completer[transmission-remote]

set edit:completion:arg-completer[P] = $edit:completion:arg-completer[pacman]
fn P {|@a| pacman $@a}

set edit:completion:arg-completer[sys] = $edit:completion:arg-completer[systemctl]
fn sys {|@a| systemctl $@a}

set edit:completion:arg-completer[e] = $edit:completion:arg-completer[$E:EDITOR]
fn e {|@a| (external $E:EDITOR) $@a}

fn f {|@a| fusermount $@a}
fn F {|@a| fusermount -u $@a}

set edit:completion:arg-completer[g] = $edit:completion:arg-completer[git]
fn g {|@a| git $@a}

fn c {|@a| ./configure $@a}

set edit:completion:arg-completer[ka] = $edit:completion:arg-completer[killall]
fn ka {|@a| killall $@a}

set edit:completion:arg-completer[z] = $edit:completion:arg-completer[zathura]
fn z {|@a| zathura $@a}
fn um {|@a| udiskie-mount $@a}
fn ud {|@a| udiskie-umount $@a}

fn hx {|@rest| e:hx $@rest}
fn helix {|@rest| e:helix $@rest}

if (has-external hx) {
  set helix~ = {|@rest| e:hx $@rest}
} elif (has-external helix) {
  set hx~ = {|@rest| e:helix $@rest}
}

# automatically raise to root
set edit:completion:arg-completer[sy] = $edit:completion:arg-completer[systemctl]
fn sy {|@rest| sudo systemctl $@rest}

set edit:completion:arg-completer[E] = $edit:completion:arg-completer[$E:EDITOR]
fn E {|@rest| sudo $E:EDITOR $@rest}

set edit:completion:arg-completer[m] = $edit:completion:arg-completer[mount]
set edit:completion:arg-completer[u] = $edit:completion:arg-completer[umount]
fn m {|@rest| sudo mount $@rest}
fn u {|@rest| sudo umount $@rest}

# Git stuff for all branches
fn gua { git remote | grep -v "^upstream$" | xargs -l git push }
fn gum { git remote | grep -v "^upstream$" | xargs -I _ git push _ master }

# Using better utils
fn gzip {|@rest| e:gzip $@rest}
fn bzip2 {|@rest| e:bzip2 $@rest}

if (has-external pigz) {
  set gzip~ = {|@rest| e:pigz $@rest}
}

if (has-external pbzip2) {
  set bzip2~ = {|@rest| e:pbzip2 $@rest}
}

# Email
fn abook { abook -C (path:join $E:XDG_CONFIG_HOME abook abookrc) --datafile (path:join $E:XDG_DATA_HOME abook addressbook) }
fn mbsync { mbsync -c (path:join $E:XDG_CONFIG_HOME isync mbsyncrc) }

set-env FZF_DEFAULT_OPTS "--layout=reverse --height 40%"

# Some convience functions that are a bit more complex but not script worthy
fn vdesc {
  |file|
  ffprobe -v quiet -print_format json -show_format $file | jq ".format.tags.DESCRIPTION" | sed 's/\\n/\n/g'
}

# Disable ^S and ^q
stty -ixon

# Fix gpg entry
set-env GPG_TTY (tty)

if (re:match '^xterm-' $E:TERM) {
  set-env TERM "xterm"
} elif (not (has-env TERM)) {
  set-env TERM "xterm"
} 

set-env TERMINAL $E:TERM

set-env RUSTC_WRAPPER sccache
set-env VAULT_ADDR "https://vault.aftix.xyz"
set-env DOCKER_HOST "unix://"(path:join $E:XDG_RUNTIME_DIR docker.sock)
set-env SSH_AUTH_SOCK (path:join $E:XDG_RUNTIME_DIR ssh-agent.socket)

if (has-external brew) {
  eval (^
    brew shellenv |^
    grep -v "PATH" |^
    each {|l| re:replace '^export' 'set-env' $l} |^
    each {|l| re:replace '=' ' ' $l} |^
    each {|l| re:replace '$;' '' $l} |^
    to-terminated " "^
  )
}

mkdir -p $E:XDG_CONFIG_HOME
mkdir -p $E:XDG_DATA_HOME
mkdir -p $E:XDG_CACHE_HOME
mkdir -p $E:XDG_RUNTIME_DIR
mkdir -p $E:WINEPREFIX
mkdir -p $E:PASSWORD_STORE_DIR
mkdir -p $E:GOPATH
mkdir -p (path:join $E:HOME .local bin)

use mamba
set mamba:cmd = conda
set mamba:root = (path:join $E:HOME .conda)
use completions/molecule
use completions/crev
use jump
use iterm2
use nix

fn add_bookmark {|@args| jump:add_bookmark $@args }
fn remove_bookmark {|@args| jump:remove_bookmark $@args }
fn jump {|@args| jump:jump $@args }
fn cd {|@args| jump:jump $@args }

eval (starship init elvish)
iterm2:init
