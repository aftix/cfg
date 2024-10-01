# Add bookmarks and other navigation features to nushell
# NOTE: must be used after any changes to the starting directory

# Save the core cd command
alias core-cd = cd

######### JUMPS #########
# jumplists - Not persistent. Keeps track of per-session directory information - inspired by the helix editor
#   alt-o goes back on the jumplist stack (does not pop ; non destructive to jumplist)
#   Shift-alt-o goes back on the jumplist stack (destructive)
#   alt-i goes forward on the jumplist stack
#   alt-e brings up fzf to select a jump point to echo into the shell prompt
#   alt-j  brings up a fuzzy picker for all items in jumplist
#   Shift-alt-j adds the current directory explicitly to the jump list
#   Shift-alt-ctrl-j removes the current directory from the explicit jump list
# 
#   These use functions jump_back, jump_pop, jump_forward, jump_pick, jump_mark, and jump_unmark, respectively
#   In addition, jump is a wrapper around the cd command that adds the destination to the jump stack (removing everything above the current jumppoint)


# Remove everything above current position on jump stack and cd, pushing new directory to jump stack
export def --env jump_to [to?: string] {
  let to = if $to == null { "~" } else { $to }
  let to = ($to | path expand)
  core-cd $to

  mut current = (stor open | query db 'SELECT * FROM jumps WHERE current = true' | get $.0)
  stor delete --table-name jumps --where-clause $"idx > ($current.idx)" | ignore
  $current.current = false
  stor update --table-name jumps --update-record $current --where-clause $'idx = ($current.idx)' | ignore
  let new = {idx: ($current.idx + 1) location: $to current: true}
  stor insert --table-name jumps --data-record $new | ignore
}

# Go backwards one step in the jump stack if possible, non-destructively
export def --env jump_back [] {
  mut current = (stor open | query db 'SELECT * FROM jumps WHERE current = true' | get $.0)
  if $current.idx == 0 {
    return
  }

  mut prev = (stor open | query db $'SELECT * FROM jumps WHERE idx = ($current.idx - 1)' | get $.0)
  core-cd $prev.location
  
  $current.current = false
  $prev.current = true
  stor update --table-name jumps --update-record $current --where-clause $'idx = ($current.idx)' | ignore
  stor update --table-name jumps --update-record $prev --where-clause $'idx = ($prev.idx)' | ignore
}

# Go backwards one step in the jump stack if possible, destructively
export def --env jump_pop [] {
  let current = (stor open | query db 'SELECT * FROM jumps WHERE current = true' | get $.0)
  if $current.idx == 0 {
    return
  }

  mut prev = (stor open | query db $'SELECT * FROM jumps WHERE idx = ($current.idx - 1)' | get $.0)
  core-cd $prev.location
  
  $prev.current = true
  stor delete --table-name jumps --where-clause $'idx = ($current.idx)' | ignore
  stor update --table-name jumps --update-record $prev --where-clause $'idx = ($prev.idx)' | ignore
}

# Goes forwards in the jump stack if possible
export def --env jump_forward [] {
  mut current = (stor open | query db 'SELECT * FROM jumps WHERE current = true' | get $.0)
  let next = (stor open | query db $'SELECT * FROM jumps WHERE idx = ($current.idx + 1)')
  if ($next | length) == 0 {
    return
  }

  mut next = $next.0
  core-cd $next.location

  $current.current = false
  $next.current = true
  stor update --table-name jumps --update-record $current --where-clause $'idx = ($current.idx)' | ignore
  stor update --table-name jumps --update-record $next --where-clause $'idx = ($next.idx)' | ignore
}

# Opens a fuzzy finder on jump stack + explicitly marked jump points
export def jump_pick [] {
  let jumps = (stor open | query db 'SELECT * FROM jumps' | sort-by idx --reverse | select location)
  let jumps_explicit = (stor open | query db 'SELECT * from jumps_explicit' | select location)
  mut to = '.'
  try {
    $to = ($jumps_explicit | append $jumps
    | uniq
    | to csv --noheaders --separator ' '
    | fzf -i --border --header Jumps -n '1,3..'
    )
  }
  if $to == '.' { return }
  $to
}

# Jumps destructively to a fuzzy picked jump point
export def --env jump_to_pick [] {
  try { jump_pick | jump_to $in } | ignore
}

# Marks pwd explicity as a jump point
export def jump_mark [] {
  let loc = (pwd)
  let jumps = (stor open | query db $"SELECT * FROM jumps_explicit WHERE location = '($loc | str replace --all "'" "\\'")'")
  if ($jumps | length) > 0 {
    return
  }
  stor insert --table-name jumps_explicit --data-record {location: $loc} | ignore
}

# Unmarks pwd explicitly as a jump point
export def jump_unmark [] {
  try {
    stor delete --table-name jumps_explicit --where-clause $"location = '(pwd | str replace --all "'" "\\'")'" | ignore
  }
}

######### BOOKMARKS ########
# bookmarks - kept in $XDG_CONFIG_HOME/bookmarks, named list of directories managed by this module
#   bookmarks can be added with add_bookmark <name> to add the cwd (will check for conflicts and prompt for overwriting previous values)
#   bookmarks can be removed with remove_bookmark <name> (with tab completion)
#   Alt-x brings up a fuzzy finder to jump to a bookmark
#   Shift-alt-x lets you insert a bookmark path at the cursor position in the shell buffer


def parse_bmarks [] {
  (from csv --separator ' ' --noheaders --trim all
  | rename --column { column0: name column1: location}
  )
}


def sanitize_location [] {
  (str replace --all $env.XDG_CONFIG_HOME '$XDG_CONFIG_HOME'
   | str replace --all $env.XDG_DATA_HOME '$XDG_DATA_HOME'
   | str replace --all $env.XDG_CACHE_HOME '$XDG_CACHE_HOME'
   | str replace --all $env.HOME '$HOME'
  )
}

export def add_bookmark [name @rest] {
  let bmarks = (stor open | query db 'SELECT * FROM jump_bookmarks')
  let conflicting_name = ($bmarks | each {
    (str upcase $name) == (str upcase $in.name)
  } | reduce {|it, acc| $acc or $it})

  let location = (pwd | sanatize_location)
  if $conflicting_name {
    print  $"Overwrite bookmark for ($name)?"
    let choice = ([no yes] | input list)
    if choice == "no" {
      print "Not overwriting."
      return
    }

    stor update --table-name jump_bookmarks --update-record {name: $name location: $location}
  } else {
    stor insert --table-name jump_bookmarks --data-record {name: $name location: $location} 
  }

  let bfile = $env.XDG_DATA_HOME ++ '/bookmarks'
  stor open | query db 'SELECT * FROM jump_bookmarks' | to csv --noheaders --separator ' ' | sanitize_location | save --force $bfile
}

export def remove_bookmark [] {
  let bmarks = (stor open | query db 'SELECT * FROM jump_bookmarks')

  mut name = '.'
  try { 
    $name = ($bmarks | to csv --noheaders --separator ' ' | fzf --border -i)
  }
  if $name == '.' {
    return
  }

  let bfile = $env.XDG_DATA_HOME ++ '/bookmarks'
  stor delete --table-name jump_bookmarks --where-clause $"name == '($name)'"
  stor open | query db 'SELECT * from jump_bookmarkl' | to csv --noheaders --separator ' ' | save --force $bfile
}

export def get_bookmark [] {
  mut location = '.'
  try {
    $location = (stor open
    | query db 'SELECT * FROM jump_bookmarks'
    | sort-by name
    | uniq-by name
    | to csv --noheaders --separator ' '
    | fzf -i --border --header Bookmarks -n '1,3..'
    )
  }
  if $location == '.' { return }

  ($location
    | split row --number 2 ' '
    | get $.1
    | $"echo \"($in)\""
    | bash -ls
  )
}

export def --env goto_bookmark [] {
  try {get_bookmark | jump_to $in} | ignore
}

export def --env jump_init [] {
  try { stor delete --table-name jumps } catch { } | ignore
  stor create --table-name jumps --columns {idx: int location: str current: bool} | ignore
  try { stor delete --table-name jumps_explicit } catch { } | ignore
  stor create --table-name jumps_explicit --columns {location: str} | ignore

  stor insert --table-name jumps --data-record {idx: 0 location: (pwd) current: true} | ignore

  try { stor delete --table-name jump_bookmarks } catch { } | ignore
  stor create --table-name jump_bookmarks --columns {name: str location: str} | ignore

  (open ($env.XDG_DATA_HOME ++ '/bookmarks')
    | parse_bmarks
    | each {stor insert --table-name jump_bookmarks}
    | ignore
  )

  # Module keybindings
  let jump_keybindings = [
    {
      name: jump_back
      modifier: alt
      keycode: char_o
      mode: [emacs vi_normal vi_insert]
      event: [
        { edit: Clear }
        { send: executehostcommand cmd: "jump_back" }
        { send: Enter }
      ]
    }
    {
      name: jump_pop
      modifier: shift_alt
      keycode: char_o
      mode: [emacs vi_normal vi_insert]
      event: [
        { edit: Clear }
        { send: executehostcommand cmd: "jump_pop" }
        { send: Enter }
      ]
    }
    {
      name: jump_forward
      modifier: alt
      keycode: char_i
      mode: [emacs vi_normal vi_insert]
      event: [
        { edit: Clear }
        { send: executehostcommand cmd: "jump_forward" }
        { send: Enter }
      ]
    }
    {
      name: insert_jump
      modifier: alt
      keycode: char_e
      mode: [emacs vi_insert]
      event: [
        { edit: Insertstring value: "(jump_pick)" }
      ]
    }
    {
      name: jump_pick
      modifier: alt
      keycode: char_j
      mode: [emacs vi_normal vi_insert]
      event: [
        { edit: Clear }
        { send: executehostcommand cmd: "jump_to_pick" }
        { send: Enter }
      ]
    }
    {
      name: jump_mark
      modifier: alt_shift
      keycode: char_j
      mode: [emacs vi_normal vi_insert]
      event: { send: executehostcommand cmd: "jump_mark" }
    }
    {
      name: jump_unmark
      modifier: control_alt_shift
      keycode: char_j
      mode: [emacs vi_normal vi_insert]
      event: { send: executehostcommand cmd: "jump_unmark" }
    }
    {
      name: goto_bmark
      modifier: alt
      keycode: char_x
      mode: [emacs vi_normal vi_insert]
      event: [
        { edit: Clear }
        { send: executehostcommand cmd: "goto_bookmark" }
        { send: Enter }
      ]
    }
    {
      name: insert_bmark
      modifier: shift_alt
      keycode: char_x
      mode: [emacs vi_insert]
      event: [
        { edit: Insertstring value: "(get_bookmark)" }
      ]
    }
  ]
  
  if $env.config? == null {
    $env.config = {keybindings: $jump_keybindings}
  } else {
    $env.config.keybindings = ($env.config.keybindings? | append $jump_keybindings)
  }
}

# replace core cd
export def --env cd [to?: string] { jump_to $to }
