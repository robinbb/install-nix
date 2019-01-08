## Shake for Scripting

Some programming is "scripty" - meaning that it is mostly about glueing
together other command line utilities to do the work. Utilities like
`terraform`, `kubectl`, `docker`, and `git` are frequently employed while
working within Engine ML's problem domain. The `emlctl` program is very
scripty, as are many of the shell scripts that accomplish the build and CI
system.

Thesis: Scripty programming's main challenge is the management of the
dependencies of the utilities being run.

A given utility will often need:

* environment variables set (eg. `AWS_ACCESS_KEY_ID`)
* subprograms authored (eg. `awk` scripts or Terraform `.tf` code)
* configuration files placed in certain locations (eg. `~/.kube/config.yaml`)
* permissions for directories to be set (eg. `~/.ssh`)
* the proper command line switches given (eg. `--auto-approve`)
* to be invoked from exactly the right directory
* ...and more.

These are some dependencies for one utility. But the utilities interact with
other utilities.

The utilities themselves generate output and have side effects (eg.
deploying cloud resources) which are then consumed by other utilities. The
utility invocations must occur in the proper order.

So, the programmer must write script code which satisfy both the dependencies
of each utility individually and the depedencies between utilities. This is
difficult to get right.

In (imperative) programming languages that are commonly seen as the
candidates in which to write scripty programs (eg. Bash, Python, Lua,
JavaScript), programmers must manage the dependencies themselves. For
example, if a programer wants utility A to query cloud resources created by
utility B, then they must arrange to invoke utility B and then to invoke
utility A. The mental effort required to understand the dependency
relationships in a complex scripty program is a substantial barrier to
modifying and augmenting the program.

That programmer effort can be transferred to the software.

I propose that software that assists with specifying dependencies should be
used for writing in scripty programs with notable dependencies.  (Typically,
such software is described as a "build system", with notable examples being
GNU Make, Bazel, Ninja, Nix, and Shake.)

Shake is the most appropriate of the build systems for writing scripty
programs.  In addition to state-of-the-art dependency specification
functionality, Shake has several features which are very commonly used in
writing scripty programs. Above what is offered by other build systems, Shake
provides:

1. a small DSL which assists with constructing the invocations of utility
   code
2. a config file format which it parses out-of-the-box (taken from Ninja)
3. a very small DSL for constructing compile-time-typed file paths
4. build completion time prediction
5. the ability to execute arbitrary Haskell code in any part of the build
   system specification (including, for example, Amazonka-based tests).

I wrote some Shake code to replace a very 'scripty' piece of software - the
Nix-install program that performs the first phase of Nix installation. I
wrote it as an exercise to show that Shake is good at writing scripty
programs.

* [The Nix-install script](https://nixos.org/nix/install)
* [The example Shake code](https://github.com/robinbb/install-nix/blob/robinbb/change-to-haskell/Main.hs)


### Example error messages from Shake

Here are real examples of my own programming failures when writing this Nix
install script. Shake told me how to fix them.

#### Error when script insufficiently specifies dependencies

> Error when running Shake build system:
>   at Main.hs:14:5-43:
> * Depends on: /nix/var/nix/db/db.sqlite
> * Raised the exception:
> Error, file does not exist and no rule available:
>   /nix/var/nix/db/db.sqlite

#### Error when script rules do not actually produce the desired target

> Error when running Shake build system:
>   at Main.hs:18:5-43:
> ...
> * Depends on: _build/install
>   at Main.hs:32:7-26:
> * Depends on: _build/tarballs/nix-2.1.3.tar.bz2
> * Raised the exception:
> Error, rule finished running but did not produce file:
>   _build/tarballs/nix-2.1.3.tar.bz2


#### Error when multiple build rules match a target

> Error when running Shake build system:
>   at Main.hs:19:5-43:
> ...
> * Depends on: _build/bin/tar
> * Raised the exception:
> Build system error - key matches multiple rules:
>   Key type:       FileQ
>   Key value:      _build/bin/tar
>   Rules matched:  2
>   Rule 1:         "//*" %> at Main.hs:(40,5)-(46,78):
>   Rule 2:         "_build/bin/*" %> at Main.hs:(49,5)-(52,53):
> Modify your rules so only one can produce the above key
