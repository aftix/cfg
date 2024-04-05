use str

var molecule_commands = [
  &check="Use the provisioner to perform a Dry-Run"
  &cleanup="Use the provisioner to cleanup any changes made to external systems"
  &converge="Use the provisioner to configure instances"
  &create="Use the provisioner to start the instances"
  &dependency="Manage the role's dependencies"
  &destroy="Use the provisioner to destroy the instances"
  &drivers="List drivers"
  &idempotence="Use the provisioner to configure the instances and parse the output"
  &init="Initialize a new role or scenario"
  &lint="Lint the role (dependency, lint)"
  &list="List status of instances"
  &login="Log in to one instance"
  &matrix="List matrix of steps used to test instances"
  &prepare="Use the provisioner to prepare the instances into a particular"
  &reset="Reset molecule temporary folders"
  &side-effect="Use the provisioner to perform side-effects to the instances"
  &syntax="Use the provisioner to syntax check the role"
  &test="Test (dependency, lint, cleanup, destroy, syntax, create, prepare)"
  &verify="Run automated tests against instances"
]

# Complete one of the primary commands of molecule
fn complete_command {
  each {
    |key|
    edit:complex-candidate &code-suffix='' &display=$key' - '$molecule_commands[$key] $key
  } [(keys $molecule_commands)]
}

fn has_flag {
  |flag @args|
  for arg $args {
    if (or (==s $arg '--'$flag) (==s $arg '-'$flag)) {
      put $true
      return
    }
  }
  put $false
}

fn complete_flags {
  |@args|

  if (not (or 
    (has_flag 'version' $@args)
    (has_flag 'help' $@args)
    (has_flag 'debug' $@args)
    (has_flag 'no-debug' $@args)
    (has_flag 'v' $@args)
    (has_flag 'verbose' $@args)
  )) {
    edit:complex-candidate &code-suffix='' &display='--version - Show version and exit' '--version'
    edit:complex-candidate &code-suffix='' &display='--help - Show help and exit' '--help'
  }

  if (not (or
    (has_flag 'debug' $@args)
    (has_flag 'no-debug' $@args)
  )) {
    edit:complex-candidate &code-suffix='' &display='--debug - Enable debug mode' '--debug'
    edit:complex-candidate &code-suffix='' &display='--no-debug - Disable debug mode (default)' '--no-debug'
  }

  edit:complex-candidate &code-suffix='' &display='-v - Increase ansible verbosity level. Default is 0' '-v'
}

fn complete_scenario {
  |@args|

  if (not (or (has_flag 's' $@args) (has_flag 'scenario-name' $@args))) {
    edit:complex-candidate &code-suffix='' &display='-s TEXT - Name of the scenario to target. (default)' '-s'
    edit:complex-candidate &code-suffix='' &display='--scenario-name TEXT - Name of the scenario to target. (default)' '--scenario-name'
  }

  if (or (==s $args[-2] '-s') (==s $args[-2] '--scenario-name')) {
    var scenarios = [(find molecule -type d -mindepth 1 -maxdepth 1 | cut -d'/' -f2 | from-lines)]
    for scenario $scenarios {
      edit:complex-candidate &code-suffix='' $scenario
    }
  } elif (not (has_flag 'help' $@args)) {
    edit:complex-candidate &code-suffix='' &display='--help - Show help and exit' '--help'
  }
}

fn has_command {
  |@args|
  for arg $args[..-1] {
    if (not (str:has-prefix $arg '-')) {
      put $true
      return
    }
  }

  put $false
}

fn complete {
  |command @rest|
  if (!=s $command molecule) {
    return
  }

  if (has_command $@rest) {
    complete_scenario $@rest
  } elif (str:has-prefix $rest[-1] '-') {
    complete_flags $@rest
  } else {
    complete_command
  }
}

set edit:completion:arg-completer[molecule] = $complete~
