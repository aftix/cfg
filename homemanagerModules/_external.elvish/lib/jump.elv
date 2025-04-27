# Adds bookmarks and other navigation features to elvish
# NOTE: must be used after any changes to the starting directory

use str
use path
use re
use os

# Utility function for allowing canceling of fzf
fn safe_fzf {
  |@all|

  defer $edit:clear~
  
  sort | uniq | try { 
    fzf --border $@all 2> $os:dev-tty
  } catch e {
    echo '.'
  } | put (all)
}

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

var jump_stack = [(pwd)] # Will always be at least 1 long
var jump_saved = []
var jump_position = (num 0)

# Remove everything above current position on jump stack and cd, pushing new directory to jump stack
fn jump {
  |@all|

  put $@all | cd (all)

  # Remove all jump positions above the current one on the stack
  if (< $jump_position (count $jump_stack)) {
    set jump_stack = $jump_stack[0..(+ $jump_position 1)]
  }
  set jump_stack = [$@jump_stack (pwd)]
  set jump_position = (+ $jump_position 1)
}
set edit:completion:arg-completer[jump] = $edit:complete-filename~

# Go backwards one step in the jump stack if possible, non-destructively
fn jump_back {
  if (== $jump_position 0) {
    return
  }

  set jump_position = (- $jump_position 1)
  cd $jump_stack[$jump_position]
}


# Go backwards one step in the jump stack if possible, destructively
fn jump_pop {
  if (== $jump_position 0) {
    return
  }

  set jump_stack = $jump_stack[0..$jump_position]
  set jump_position = (- $jump_position 1)
  cd $jump_stack[$jump_position]
}

# Go forwards in the jump stack if possible
fn jump_forward {
  if (== $jump_position (- (count $jump_stack) 1)) {
    return
  }

  set jump_position = (+ $jump_position 1)
  cd $jump_stack[$jump_position]
}

# Opens a fuzzy finder on jump stack + explicitly marked jump points
# changes directory to the given jump point (Removes the jump stack above the cwd)
fn jump_pick {
  var choice = (each {
    |jumppoint|
    echo $jumppoint
  } [$@jump_stack $@jump_saved] | safe_fzf --tac --header 'Jumplist' -i)

  if (==s $choice '.') {
    return
  }

  # Remove all jump positions above the current one on the stack
  if (< $jump_position (count $jump_stack)) {
    set jump_stack = $jump_stack[0..(+ $jump_position 1)]
  }
  cd $choice
  set jump_stack = [$@jump_stack (pwd)]
  set jump_position = (+ $jump_position 1)
}

# Opens a fuzzy finder on jump stack + explicitly marked jump points
# echos the jump point path to the cursor position in the shell prompt
fn jump_echo {
  var choice = (each {
    |jumppoint|
    echo $jumppoint
  } [$@jump_stack $@jump_saved] | safe_fzf --tac --header 'Jumplist (echo)' -i)

  if (==s $choice '.') {
    return
  }

  edit:insert-at-dot $choice
}

# Marks the cwd explicitly as a jump point (if it already is marked, this is a no-op)
fn jump_mark {
  set jump_saved = [(each {
    |jumppoint|
    echo $jumppoint
  } [$@jump_saved (pwd)] | sort | uniq | from-lines)]
}

# Unmarks the cwd explicitly as a jump point (if it is marked)
fn jump_unmark {
  set jump_saved = [(each {
    |jumppoint|
    echo $jumppoint
  } $jump_saved | grep -iv '^'(pwd)'$' | sort | uniq | from-lines)]
}

set edit:insert:binding[Alt-o] = $jump_back~
set edit:insert:binding[Alt-O] = $jump_pop~
set edit:insert:binding[Alt-i] = $jump_forward~
set edit:insert:binding[Alt-e] = $jump_echo~
set edit:insert:binding[Alt-j] = $jump_pick~
set edit:insert:binding[Alt-J] = $jump_mark~
set edit:insert:binding[Alt-Ctrl-J] = $jump_unmark~

######### BOOKMARKS ########
# bookmarks - kept in $XDG_CONFIG_HOME/bookmarks, named list of directories managed by this module
#   bookmarks can be added with add_bookmark <name> to add the cwd (will check for conflicts and prompt for overwriting previous values)
#   bookmarks can be removed with remove_bookmark <name> (with tab completion)
#   Alt-x brings up a fuzzy finder to jump to a bookmark
#   Shift-alt-x lets you insert a bookmark path at the cursor position in the shell buffer

var bfile = (path:join $E:XDG_DATA_HOME bookmarks)
fn parse_bmarks {
  put [(each {
    |line|
    var line = (re:replace '#.*$' '' $line | str:trim-space (all))
    if (!=s $line '') {
      put [(each {
        |match|
        if (>= $match[start] 0) {
          put $match[text]
        }
      } [(re:find "[^\\s\"']+|\"([^\"]*)\"|'([ ^']*)'" $line)])]
    }
  } [(all)])]
}

var bookmarks = (from-lines < $bfile | parse_bmarks)
fn reload_bmarks {
  set bookmarks = (from-lines < $bfile | parse_bmarks)
}

fn sanitize_location {
  |location|
   echo $location | tr -d '\n' |^
   str:replace $E:XDG_CONFIG_HOME "$XDG_CONFIG_HOME" (slurp) |^
   str:replace $E:XDG_DATA_HOME "$XDG_DATA_HOME" (all) |^
   str:replace $E:XDG_CACHE_HOME "$XDG_CACHE_HOME" (all) |^
   str:replace $E:HOME "$HOME" (all)
}

fn add_bookmark {
  |name @rest|
  var conflicting_name = (each {
    |bmark|
    if (str:equal-fold $bmark[0] $name) {
      put $true
    }
  } $bookmarks | has-value [(all)] $true)
  if $conflicting_name {
    print 'Overwrite bookmark for '$name'? (Y/N) '
    var override_choice = (read-line)
    if (not (re:match '((?i)^y(es)?$)' $override_choice)) {
      echo 'Not overwriting'
      return
    }
  }

  var location = (sanitize_location (pwd))
  
  set bookmarks = [(each {
    |bmark|
    if (not (str:equal-fold $bmark[0] $name)) {
      put $bmark
    }
  } $bookmarks) [$name $location (print $@rest)]]

  each {
    |bmark|
    echo $@bmark
  } $bookmarks > $bfile
}

fn remove_bookmark {
  |name|

  set bookmarks = [(each {
    |bmark|
    if (not (str:equal-fold $bmark[0] $name)) {
      put $bmark
    }
  } $bookmarks)]

  each {
    |bmark|
    echo $@bmark
  } $bookmarks > $bfile
}

fn complete {
  |command @rest|

  if ( or (!=s $command remove_bookmark) (> (count $rest) 1) ) {
    return
  } 

  for candidate $bookmarks {
    if (== (count $candidate) 2) {
      edit:complex-candidate &code-suffix='' &display=$candidate[0]' - '$candidate[1] $candidate[0]
    } elif (== (count $candidate) 3) {
      edit:complex-candidate &code-suffix='' &display=$candidate[0]' - '$candidate[1]' ('$candidate[2]')' $candidate[0]
    }
  }
}

set edit:completion:arg-completer[remove_bookmark] = $complete~

if (has-external fzf) {
  set edit:insert:binding[Alt-x] = {
    var selection = (each {
        |item|
        echo $item | re:replace "['\\[\\]\\n]" '' (slurp) | echo (all)
      } $bookmarks | safe_fzf --header Bookmarks -i -n 1,3.. | to-lines | awk '{print $1}')

    if (!=s $selection '.') {
      each {
        |bmark|
        if (==s $bmark[0] $selection) {
          jump (eval 'echo '(str:replace '$' '$E:' $bmark[1]))
        }
      } $bookmarks
    }
  }

  set edit:insert:binding[Alt-X] = {
    var selection = (each {
        |item|
        echo $item | re:replace "['\\[\\]\\n]" '' (slurp) | echo (all)
      } $bookmarks | safe_fzf --header 'Bookmarks (echo)' -i -n 1,3.. | to-lines | awk '{print $1}')

    if (!=s $selection '.') {
      each {
        |bmark|
        if (==s $bmark[0] $selection) {
          edit:insert-at-dot (eval 'echo '(str:replace '$' '$E:' $bmark[1]))
        }
      } $bookmarks
    }
  }
}
