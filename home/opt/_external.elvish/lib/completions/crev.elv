use str

fn crev_completion {
    |@words|

    if (< (count $words) 2) {
        return
    }

    if (!=s $words[0] 'cargo-crev') {
        return
    }

    fn spaces {
        |n|
        repeat $n ' ' | str:join ''
    }
    fn cand {
        |text desc|
        edit:complex-candidate $text &display=$text' '(spaces (- 14 (wcswidth $text)))$desc
    }
    var command = 'cargo;crev'

    if (> (count $words) 1) {
        for word $words[1..-1] {
            if (str:has-prefix $word '-') {
                break
            }
            set command = $command';'$word
        }
    }
    var completions = [
        &'cargo;crev'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand config 'Local configuration'
            cand crate 'Crate related operations (review, verify...)'
            cand id 'Id (own and of other users)'
            cand proof 'Find a proof in the proof repo'
            cand repo 'Proof Repository'
            cand trust 'Add a Trust proof by an Id or a URL'
            cand wot 'Web of Trust'
            cand goto 'Shortcut for `crate goto`'
            cand open 'Shortcut for `crate open`'
            cand publish 'Shortcut for `repo publish`'
            cand review 'Shortcut for `crate review`'
            cand update 'Shortcut for `repo update`'
            cand verify 'Shortcut for `crate verify`'
        }
        &'cargo;crev;config'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand edit 'Edit the config file'
            cand completions 'Completions'
            cand dir 'Print the dir containing config files'
            cand data-dir 'Print the dir containing data files'
            cand cache-dir 'Print the dir containing cache files'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;config;edit'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;config;completions'= {
            cand --shell 'shell'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;config;dir'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;config;data-dir'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;config;cache-dir'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;config;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand goto 'Start a shell in source directory of a crate under review'
            cand open 'Open the source code of a crate'
            cand expand 'WIP: Expand the crate source using `cargo-expand` like functionality'
            cand clean 'Clean the source code directory of a crate (eg. after review)'
            cand diff 'Diff between two versions of a package'
            cand dir 'Display the path of the source code directory of a crate'
            cand verify 'Verify dependencies'
            cand mvp 'Parameters describing trust graph traversal'
            cand review 'Review a crate (code review, security advisory, flag issues)'
            cand unreview 'Unreview (overwrite with an null review)'
            cand search 'Search crates on crates.io sorting by review count'
            cand info 'Parameters describing trust graph traversal'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;crate;goto'= {
            cand -v 'v'
            cand --vers 'vers'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;open'= {
            cand --cmd 'Shell command to execute with crate directory as an argument. Eg. "code --wait -n" for VSCode'
            cand -v 'v'
            cand --vers 'vers'
            cand --diff 'Review the delta since the given version'
            cand --cmd-save 'Save the `--cmd` argument to be used a default in the future'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;expand'= {
            cand -v 'v'
            cand --vers 'vers'
            cand --diff 'Review the delta since the given version'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;clean'= {
            cand -v 'v'
            cand --vers 'vers'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;diff'= {
            cand --src 'Source version - defaults to the last reviewed one'
            cand --dst 'Destination version - defaults to the current one'
            cand --trust 'Minimum trust level required'
            cand --redundancy 'Number of reviews required'
            cand --understanding 'Required understanding'
            cand --thoroughness 'Required thoroughness'
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;dir'= {
            cand -v 'v'
            cand --vers 'vers'
            cand --diff 'Review the delta since the given version'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;verify'= {
            cand --trust 'Minimum trust level required'
            cand --redundancy 'Number of reviews required'
            cand --understanding 'Required understanding'
            cand --thoroughness 'Required thoroughness'
            cand --features '[cargo] Space-separated list of features to activate'
            cand --manifest-path '[cargo] Path to Cargo.toml'
            cand -Z '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --unstable-flags '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --target '[cargo] Skip targets other than specified (no value = autodetect)'
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --for-id 'Root identity to calculate the Web of Trust for [default: current user id]'
            cand --show-digest 'Show crate content digest'
            cand --show-leftpad-index 'Show crate leftpad index (recent downloads / loc)'
            cand --show-downloads 'Show crate download counts'
            cand --show-owners 'Show crate owners counts'
            cand --show-latest-trusted 'Show latest trusted version'
            cand --show-reviews 'Show reviews count'
            cand --show-loc 'Show Lines of Code'
            cand --show-issues 'Show count of issues reported'
            cand --show-geiger 'Show geiger (unsafe lines) count'
            cand --show-flags 'Show crate flags'
            cand -v 'v'
            cand --vers 'vers'
            cand --all-features '[cargo] Activate all available features'
            cand --no-default-features '[cargo] Do not activate the `default` feature'
            cand --dev-dependencies '[cargo] Activate dev dependencies'
            cand --no-dev-dependencies '[cargo] Skip dev dependencies'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand --show-all 'Show all'
            cand -i 'i'
            cand --interactive 'interactive'
            cand --skip-verified 'Display only crates not passing the verification'
            cand --skip-known-owners 'Skip crate from known owners (use `edit known` to edit the list)'
            cand --skip-indirect 'Skip dependencies that are not direct'
            cand --recursive 'Calculate recursive metrics for your packages'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;mvp'= {
            cand --trust 'Minimum trust level required'
            cand --redundancy 'Number of reviews required'
            cand --understanding 'Required understanding'
            cand --thoroughness 'Required thoroughness'
            cand --features '[cargo] Space-separated list of features to activate'
            cand --manifest-path '[cargo] Path to Cargo.toml'
            cand -Z '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --unstable-flags '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --target '[cargo] Skip targets other than specified (no value = autodetect)'
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --for-id 'Root identity to calculate the Web of Trust for [default: current user id]'
            cand -v 'v'
            cand --vers 'vers'
            cand --all-features '[cargo] Activate all available features'
            cand --no-default-features '[cargo] Do not activate the `default` feature'
            cand --dev-dependencies '[cargo] Activate dev dependencies'
            cand --no-dev-dependencies '[cargo] Skip dev dependencies'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;review'= {
            cand -v 'v'
            cand --vers 'vers'
            cand --diff 'Review the delta since the given version'
            cand --affected 'This release contains advisory (important fix)'
            cand --severity 'Severity of bug/security issue [none low medium high]'
            cand --features '[cargo] Space-separated list of features to activate'
            cand --manifest-path '[cargo] Path to Cargo.toml'
            cand -Z '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --unstable-flags '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --target '[cargo] Skip targets other than specified (no value = autodetect)'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand --no-commit 'Don''t auto-commit local Proof Repository'
            cand --print-unsigned 'Print unsigned proof content on stdout'
            cand --print-signed 'Print signed proof content on stdout'
            cand --no-store 'Don''t store the proof'
            cand --advisory 'Create advisory urging to upgrade to a safe version'
            cand --issue 'Flag the crate as buggy/low-quality/dangerous'
            cand --skip-activity-check 'skip-activity-check'
            cand --overrides 'Enable overrides suggestions'
            cand --all-features '[cargo] Activate all available features'
            cand --no-default-features '[cargo] Do not activate the `default` feature'
            cand --dev-dependencies '[cargo] Activate dev dependencies'
            cand --no-dev-dependencies '[cargo] Skip dev dependencies'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;unreview'= {
            cand -v 'v'
            cand --vers 'vers'
            cand --diff 'Review the delta since the given version'
            cand --affected 'This release contains advisory (important fix)'
            cand --severity 'Severity of bug/security issue [none low medium high]'
            cand --features '[cargo] Space-separated list of features to activate'
            cand --manifest-path '[cargo] Path to Cargo.toml'
            cand -Z '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --unstable-flags '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --target '[cargo] Skip targets other than specified (no value = autodetect)'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand --no-commit 'Don''t auto-commit local Proof Repository'
            cand --print-unsigned 'Print unsigned proof content on stdout'
            cand --print-signed 'Print signed proof content on stdout'
            cand --no-store 'Don''t store the proof'
            cand --advisory 'Create advisory urging to upgrade to a safe version'
            cand --issue 'Flag the crate as buggy/low-quality/dangerous'
            cand --skip-activity-check 'skip-activity-check'
            cand --overrides 'Enable overrides suggestions'
            cand --all-features '[cargo] Activate all available features'
            cand --no-default-features '[cargo] Do not activate the `default` feature'
            cand --dev-dependencies '[cargo] Activate dev dependencies'
            cand --no-dev-dependencies '[cargo] Skip dev dependencies'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;search'= {
            cand --count 'Number of results'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;info'= {
            cand --trust 'Minimum trust level required'
            cand --redundancy 'Number of reviews required'
            cand --understanding 'Required understanding'
            cand --thoroughness 'Required thoroughness'
            cand --features '[cargo] Space-separated list of features to activate'
            cand --manifest-path '[cargo] Path to Cargo.toml'
            cand -Z '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --unstable-flags '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --target '[cargo] Skip targets other than specified (no value = autodetect)'
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --for-id 'Root identity to calculate the Web of Trust for [default: current user id]'
            cand -v 'v'
            cand --vers 'vers'
            cand --all-features '[cargo] Activate all available features'
            cand --no-default-features '[cargo] Do not activate the `default` feature'
            cand --dev-dependencies '[cargo] Activate dev dependencies'
            cand --no-dev-dependencies '[cargo] Skip dev dependencies'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;crate;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand new 'Create a new Id'
            cand export 'Export your own Id'
            cand import 'Import an Id as your own'
            cand current 'Show your current Id'
            cand switch 'Change current Id'
            cand passwd 'Change passphrase'
            cand set-url 'Change public HTTPS repo URL for the current Id'
            cand trust 'Trust an Id'
            cand untrust 'Untrust (remove) trust'
            cand distrust 'Distrust an Id'
            cand query 'Query Ids'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;id;new'= {
            cand --url 'Publicly-visible HTTPS URL of a git repository to be associated with the new Id'
            cand --github-username 'Github username (instead of --url)'
            cand --https-push 'Use public HTTP URL for both pulling and pushing. Otherwise SSH is used for push'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;export'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;import'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;current'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;switch'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;passwd'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;set-url'= {
            cand --https-push 'Setup `https` instead of recommended `ssh`-based push url'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;trust'= {
            cand --level 'Shortcut for setting trust level without editing'
            cand --overrides 'Enable overrides suggestions'
            cand --no-commit 'Don''t auto-commit local Proof Repository'
            cand --print-unsigned 'Print unsigned proof content on stdout'
            cand --print-signed 'Print signed proof content on stdout'
            cand --no-store 'Don''t store the proof'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;untrust'= {
            cand --level 'Shortcut for setting trust level without editing'
            cand --overrides 'Enable overrides suggestions'
            cand --no-commit 'Don''t auto-commit local Proof Repository'
            cand --print-unsigned 'Print unsigned proof content on stdout'
            cand --print-signed 'Print signed proof content on stdout'
            cand --no-store 'Don''t store the proof'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;distrust'= {
            cand --level 'Shortcut for setting trust level without editing'
            cand --overrides 'Enable overrides suggestions'
            cand --no-commit 'Don''t auto-commit local Proof Repository'
            cand --print-unsigned 'Print unsigned proof content on stdout'
            cand --print-signed 'Print signed proof content on stdout'
            cand --no-store 'Don''t store the proof'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;query'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand current 'Parameters describing trust graph traversal'
            cand all 'Parameters describing trust graph traversal'
            cand own 'Parameters describing trust graph traversal'
            cand trusted 'Parameters describing trust graph traversal'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;id;query;current'= {
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;query;all'= {
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --for-id 'for-id'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;query;own'= {
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;query;trusted'= {
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --for-id 'for-id'
            cand --trust 'Minimum trust level required'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;query;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;id;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;proof'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand find 'Find a proof'
            cand reissue 'Reissue proofs with current id'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;proof;find'= {
            cand --crate 'crate'
            cand --vers 'vers'
            cand --author 'Find a proof by a crev Id'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;proof;reissue'= {
            cand --crate 'crate'
            cand --vers 'vers'
            cand --author 'Reissue all proofs by a crev Id. Mandatory'
            cand --comment 'Comment for human readers. Mandatory'
            cand --skip-reissue-check 'Skip check if we already reissued a review using the current id'
            cand --no-commit 'Don''t auto-commit local Proof Repository'
            cand --print-unsigned 'Print unsigned proof content on stdout'
            cand --print-signed 'Print signed proof content on stdout'
            cand --no-store 'Don''t store the proof'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;proof;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand publish 'Publish to remote repository'
            cand update 'Update data from online sources (proof repositories, crates.io)'
            cand git 'Run raw git commands in the local proof repository'
            cand edit 'Edit README.md of the current Id, ...'
            cand import 'Import proofs'
            cand query 'Query proofs'
            cand fetch 'Fetch proofs from external sources'
            cand dir 'Print the dir containing local copy of the proof repository'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;repo;publish'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;update'= {
            cand --features '[cargo] Space-separated list of features to activate'
            cand --manifest-path '[cargo] Path to Cargo.toml'
            cand -Z '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --unstable-flags '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --target '[cargo] Skip targets other than specified (no value = autodetect)'
            cand --all-features '[cargo] Activate all available features'
            cand --no-default-features '[cargo] Do not activate the `default` feature'
            cand --dev-dependencies '[cargo] Activate dev dependencies'
            cand --no-dev-dependencies '[cargo] Skip dev dependencies'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;git'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;edit'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand readme 'Edit your README.md file'
            cand known 'Edit your KNOWN_CRATE_OWNERS.md file'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;repo;edit;readme'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;edit;known'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;edit;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;import'= {
            cand --reset-date 'Reset proof date to current date'
            cand --no-commit 'Don''t auto-commit local Proof Repository'
            cand --print-unsigned 'Print unsigned proof content on stdout'
            cand --print-signed 'Print signed proof content on stdout'
            cand --no-store 'Don''t store the proof'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;query'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand review 'Query reviews'
            cand advisory 'Query applicable advisories'
            cand issue 'Query applicable issues'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;repo;query;review'= {
            cand -v 'v'
            cand --vers 'vers'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;query;advisory'= {
            cand -v 'v'
            cand --vers 'vers'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;query;issue'= {
            cand -v 'v'
            cand --vers 'vers'
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --trust 'Minimum trust level of the reviewers for reviews'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;query;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;fetch'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand trusted 'Parameters describing trust graph traversal'
            cand url 'Fetch from a single public proof repository'
            cand all 'Fetch all previously retrieved public proof repositories'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;repo;fetch;trusted'= {
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --for-id 'for-id'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;fetch;url'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;fetch;all'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;fetch;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;dir'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;repo;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;trust'= {
            cand --level 'Shortcut for setting trust level without editing. Possible values are: "none" or "untrust", "low", "medium", "high" and "distrust"'
            cand --overrides 'Enable overrides suggestions'
            cand --no-commit 'Don''t auto-commit local Proof Repository'
            cand --print-unsigned 'Print unsigned proof content on stdout'
            cand --print-signed 'Print signed proof content on stdout'
            cand --no-store 'Don''t store the proof'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;wot'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
            cand log 'Parameters describing trust graph traversal'
            cand help 'Prints this message or the help of the given subcommand(s)'
        }
        &'cargo;crev;wot;log'= {
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --for-id 'Root identity to calculate the Web of Trust for [default: current user id]'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;wot;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;goto'= {
            cand -v 'v'
            cand --vers 'vers'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;open'= {
            cand --cmd 'Shell command to execute with crate directory as an argument. Eg. "code --wait -n" for VSCode'
            cand -v 'v'
            cand --vers 'vers'
            cand --diff 'Review the delta since the given version'
            cand --cmd-save 'Save the `--cmd` argument to be used a default in the future'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;publish'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;review'= {
            cand -v 'v'
            cand --vers 'vers'
            cand --diff 'Review the delta since the given version'
            cand --affected 'This release contains advisory (important fix)'
            cand --severity 'Severity of bug/security issue [none low medium high]'
            cand --features '[cargo] Space-separated list of features to activate'
            cand --manifest-path '[cargo] Path to Cargo.toml'
            cand -Z '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --unstable-flags '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --target '[cargo] Skip targets other than specified (no value = autodetect)'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand --no-commit 'Don''t auto-commit local Proof Repository'
            cand --print-unsigned 'Print unsigned proof content on stdout'
            cand --print-signed 'Print signed proof content on stdout'
            cand --no-store 'Don''t store the proof'
            cand --advisory 'Create advisory urging to upgrade to a safe version'
            cand --issue 'Flag the crate as buggy/low-quality/dangerous'
            cand --skip-activity-check 'skip-activity-check'
            cand --overrides 'Enable overrides suggestions'
            cand --all-features '[cargo] Activate all available features'
            cand --no-default-features '[cargo] Do not activate the `default` feature'
            cand --dev-dependencies '[cargo] Activate dev dependencies'
            cand --no-dev-dependencies '[cargo] Skip dev dependencies'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;update'= {
            cand --features '[cargo] Space-separated list of features to activate'
            cand --manifest-path '[cargo] Path to Cargo.toml'
            cand -Z '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --unstable-flags '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --target '[cargo] Skip targets other than specified (no value = autodetect)'
            cand --all-features '[cargo] Activate all available features'
            cand --no-default-features '[cargo] Do not activate the `default` feature'
            cand --dev-dependencies '[cargo] Activate dev dependencies'
            cand --no-dev-dependencies '[cargo] Skip dev dependencies'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;crev;verify'= {
            cand --trust 'Minimum trust level required'
            cand --redundancy 'Number of reviews required'
            cand --understanding 'Required understanding'
            cand --thoroughness 'Required thoroughness'
            cand --features '[cargo] Space-separated list of features to activate'
            cand --manifest-path '[cargo] Path to Cargo.toml'
            cand -Z '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --unstable-flags '[cargo] Unstable (nightly-only) flags to Cargo'
            cand --target '[cargo] Skip targets other than specified (no value = autodetect)'
            cand --depth '[trust-graph-traversal] Maximum allowed distance from the root identity when traversing trust graph'
            cand --high-cost '[trust-graph-traversal] Cost of traversing trust graph edge of high trust level'
            cand --medium-cost '[trust-graph-traversal] Cost of traversing trust graph edge of medium trust level'
            cand --low-cost '[trust-graph-traversal] Cost of traversing trust graph edge of low trust level'
            cand --none-cost '[trust-graph-traversal] Cost of traversing trust graph edge of none trust level'
            cand --distrust-cost '[trust-graph-traversal] Cost of traversing trust graph edge of distrust trust level'
            cand --for-id 'Root identity to calculate the Web of Trust for [default: current user id]'
            cand --show-digest 'Show crate content digest'
            cand --show-leftpad-index 'Show crate leftpad index (recent downloads / loc)'
            cand --show-downloads 'Show crate download counts'
            cand --show-owners 'Show crate owners counts'
            cand --show-latest-trusted 'Show latest trusted version'
            cand --show-reviews 'Show reviews count'
            cand --show-loc 'Show Lines of Code'
            cand --show-issues 'Show count of issues reported'
            cand --show-geiger 'Show geiger (unsafe lines) count'
            cand --show-flags 'Show crate flags'
            cand -v 'v'
            cand --vers 'vers'
            cand --all-features '[cargo] Activate all available features'
            cand --no-default-features '[cargo] Do not activate the `default` feature'
            cand --dev-dependencies '[cargo] Activate dev dependencies'
            cand --no-dev-dependencies '[cargo] Skip dev dependencies'
            cand --direct '[trust-graph-traversal] Consider only direct trust relationships'
            cand --show-all 'Show all'
            cand -i 'i'
            cand --interactive 'interactive'
            cand --skip-verified 'Display only crates not passing the verification'
            cand --skip-known-owners 'Skip crate from known owners (use `edit known` to edit the list)'
            cand --skip-indirect 'Skip dependencies that are not direct'
            cand --recursive 'Calculate recursive metrics for your packages'
            cand -u 'This crate is not neccesarily a dependency of the current cargo project'
            cand --unrelated 'This crate is not neccesarily a dependency of the current cargo project'
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
        &'cargo;help'= {
            cand -h 'Prints help information'
            cand --help 'Prints help information'
            cand -V 'Prints version information'
            cand --version 'Prints version information'
        }
    ]

    $completions[$command]
}

set edit:completion:arg-completer[cargo-crev] = $crev_completion~

fn carapace_cargo {
    |@arg|

    carapace cargo elvish $@arg | from-json | each {
        |completion|

        put $completion[Messages] | all (one) | each {
            |m|
            edit:notify (styled "error: " red)$m
        }

        if (not-eq $completion[Usage] "") {
            edit:notify (styled "usage: " $completion[DescriptionStyle])$completion[Usage]
        }

        put $completion[Candidates] | all (one) | peach {
            |c|

            if (eq $c[Description] "") {
                edit:complex-candidate $c[Value] &display=(styled $c[Display] $c[Style]) &code-suffix=$c[CodeSuffix]
            } else {
                edit:complex-candidate $c[Value] &display=(styled $c[Display] $c[Style])(styled " " $completion[DescriptionStyle]" bg-default")(styled "("$c[Description]")" $completion[DescriptionStyle]) &code-suffix=$c[CodeSuffix]
            }
        }
    }
}

set edit:completion:arg-completer[cargo] = {
    |@arg|

    if (< (count $arg) 3) {
        carapace_cargo $@arg
    } elif (==s $arg[1] crev) {
        set arg = $arg[2..]
        crev_completion cargo-crev $@arg
    } else {
        carapace_cargo $@arg
    }
}
