Setup test opam-repository directory

  $ sh "scripts/setup_repo.sh"
  $ git checkout -qb new-branch-1

Tests linting of correctly formatted opam packages

  $ git apply "patches/b-correct.patch"
  $ git add .
  $ git commit -qm b-correct
  $ git log --graph --pretty=format:'%s%d'
  * b-correct (HEAD -> new-branch-1)
  * a-1 (master)
  $ revdeps_prototype lint -r . a-1.0.0.2
  Linting a-1.0.0.2 in $TESTCASE_ROOT/. ...
  No errors
  $ revdeps_prototype lint -r . b.0.0.3
  Linting b.0.0.3 in $TESTCASE_ROOT/. ...
  No errors

Setup repo for incorrect b package tests

  $ git reset -q --hard HEAD~1
  $ git apply "patches/b-incorrect-opam.patch"
  $ git add packages/
  $ echo "(lang dune 3.16)" > dune-project
  $ sh "scripts/setup_sources.sh" b 0.0.3 dune-project
  Created tarball b.0.0.3.tgz
  Updated checksum for b.0.0.3.tgz in b.0.0.3's opam file
  $ echo "foo" > bar
  $ sh "scripts/setup_sources.sh" b 0.0.4 bar
  Created tarball b.0.0.4.tgz
  Updated checksum for b.0.0.4.tgz in b.0.0.4's opam file
  $ echo "(lang dune 3.16)" > dune-project
  $ sh "scripts/setup_sources.sh" b 0.0.5 dune-project
  Created tarball b.0.0.5.tgz
  Updated checksum for b.0.0.5.tgz in b.0.0.5's opam file
  $ git commit -qm b-incorrect-opam
  $ git log --graph --pretty=format:'%s%d'
  * b-incorrect-opam (HEAD -> new-branch-1)
  * a-1 (master)


Test the following:
- [b.0.0.1] is missing the [author] field
- [b.0.0.2] has an extra unknown field
- [b.0.0.3] has a pin-depends present, and a conflict class without the required prefix; use of extra-files and a weak checksum algorithm
- [system-b.0.0.1] is using a restricted prefix in its name
- [b.0.0.4] has a missing dune-project file
- [b.0.0.5] has a dune-project file, but no explicit dependency on dune
- [b.0.0.6] has a incorrectly formatted opam file
- [b.0.0.7] has opam lint errors/warnings

  $ revdeps_prototype lint -r . b.0.0.1
  Linting b.0.0.1 in $TESTCASE_ROOT/. ...
  Error in b.0.0.1:            warning 25: Missing field 'authors'
  [1]
  $ revdeps_prototype lint -r . b.0.0.2
  Linting b.0.0.2 in $TESTCASE_ROOT/. ...
  Warning in b.0.0.2: Dubious use of 'dune subst'. 'dune subst' should always only be called with {dev} (i.e. ["dune" "subst"] {dev}) If your opam file has been autogenerated by dune, you need to upgrade your dune-project to at least (lang dune 2.7).
  Warning in b.0.0.2: The package tagged dune as a build dependency. Due to a bug in dune (https://github.com/ocaml/dune/issues/2147) this should never be the case. Please remove the {build} tag from its filter.
  Error in b.0.0.2:              error  3: File format error in 'unknown-field' at line 11, column 0: Invalid field unknown-field
  Error in b.0.0.2:              error 60: Upstream check failed: "Source not found: $TESTCASE_ROOT/b.0.0.2.tgz"
  [1]
  $ revdeps_prototype lint -r . b.0.0.3
  Linting b.0.0.3 in $TESTCASE_ROOT/. ...
  Error in b.0.0.3: Your dune-project file indicates that this package requires at least dune 3.16 but your opam file only requires dune >= 3.15.0. Please check which requirement is the right one, and fix the other.
  Error in b.0.0.3: Weak checksum algorithm(s) provided. Please use SHA-256 or SHA-512. Details: opam field extra-files contains only MD5 as checksum for 0install.install
  Error in b.0.0.3: pin-depends present. This is not allowed in the opam-repository.
  Error in b.0.0.3: extra-files present. This is not allowed in the opam-repository. Please use extra-source instead.
  Error in b.0.0.3: package with conflict class 'ocaml-host-arch' requires name prefix 'host-arch-'
  [1]
  $ revdeps_prototype lint -r . system-b.0.0.1
  Linting system-b.0.0.1 in $TESTCASE_ROOT/. ...
  Error in system-b.0.0.1: package with prefix 'system-' requires conflict class 'ocaml-system'
  [1]
  $ revdeps_prototype lint -r . b.0.0.4
  Linting b.0.0.4 in $TESTCASE_ROOT/. ...
  Warning in b.0.0.4: The package seems to use dune but the dune-project file is missing.
  [1]
  $ revdeps_prototype lint -r . b.0.0.5
  Linting b.0.0.5 in $TESTCASE_ROOT/. ...
  Warning in b.0.0.5: The package has a dune-project file but no explicit dependency on dune was found.
  [1]
  $ revdeps_prototype lint -r . b.0.0.6
  Linting b.0.0.6 in $TESTCASE_ROOT/. ...
  Error in b.0.0.6: Failed to parse the opam file
  [1]
  $ revdeps_prototype lint -r . b.0.0.7
  Linting b.0.0.7 in $TESTCASE_ROOT/. ...
  Error in b.0.0.7:              error 23: Missing field 'maintainer'
  Error in b.0.0.7:            warning 25: Missing field 'authors'
  [1]

Setup repo for name collision tests

  $ git reset -q --hard HEAD~1
  $ git apply "patches/a_1-name-collision.patch"
  $ git add .
  $ git commit -qm a_1-name-collision
  $ git log --graph --pretty=format:'%s%d'
  * a_1-name-collision (HEAD -> new-branch-1)
  * a-1 (master)

Tests the package name collision detection by adding a version of a package
[a_1] that conflicts with the existing [a-1] package

  $ revdeps_prototype lint -r . --newly-published a_1.0.0.1
  Linting a_1.0.0.1 in $TESTCASE_ROOT/. ...
  Warning in a_1.0.0.1: Possible name collision with package 'a-1'
  [1]

Setup repo for more name collision tests

  $ git checkout -q master
  $ git apply "patches/levenshtein-1.patch"
  $ git add .
  $ git commit -qm levenshtein-1
  $ git checkout -qb new-branch-2
  $ git apply "patches/levenshtein-2.patch"
  $ git add .
  $ git commit -qm levenshtein-2
  $ git log --graph --pretty=format:'%s%d'
  * levenshtein-2 (HEAD -> new-branch-2)
  * levenshtein-1 (master)
  * a-1

Tests the package name collisions detection by adding initial packages [field],
[field1] and [fieldfind] to master, and new packages [fielf], [fielffind], and
[fielffinder] to the new branch to test various positive and negative cases

  $ revdeps_prototype lint -r . --newly-published fielf.0.0.1
  Linting fielf.0.0.1 in $TESTCASE_ROOT/. ...
  Warning in fielf.0.0.1: Possible name collision with package 'field1'
  [1]
  $ revdeps_prototype lint -r . --newly-published field1.0.0.2
  Linting field1.0.0.2 in $TESTCASE_ROOT/. ...
  Warning in field1.0.0.2: Possible name collision with package 'fielf'
  [1]
  $ revdeps_prototype lint -r . --newly-published fieffinder.0.0.1
  Linting fieffinder.0.0.1 in $TESTCASE_ROOT/. ...
  Warning in fieffinder.0.0.1: Possible name collision with package 'fieffind'
  [1]
  $ revdeps_prototype lint -r . --newly-published fieffind.0.0.1
  Linting fieffind.0.0.1 in $TESTCASE_ROOT/. ...
  Warning in fieffind.0.0.1: Possible name collision with package 'fieffinder'
  Warning in fieffind.0.0.1: Possible name collision with package 'fieldfind'
  [1]

Setup repo for unnecessary fields tests

  $ git reset -q --hard HEAD~2
  $ git apply "patches/a-1-unnecessary-fields.patch"
  $ git add .
  $ git commit -qm unnecessary-fields-a-1
  $ git log --graph --pretty=format:'%s%d'
  * unnecessary-fields-a-1 (HEAD -> new-branch-2)
  * a-1

Test presence of unnecessary fields in a-1.0.0.2 package

  $ revdeps_prototype lint -r . a-1.0.0.2
  Linting a-1.0.0.2 in $TESTCASE_ROOT/. ...
  Warning in a-1.0.0.2: Unnecessary field 'name'. It is suggested to remove it.
  Warning in a-1.0.0.2: Unnecessary field 'version'. It is suggested to remove it.
  [1]

Setup repo for unmatched name and version test

  $ git reset -q --hard HEAD~1
  $ git apply "patches/a-1-unmatched-name-version.patch"
  $ git add .
  $ git commit -qm unmatched-name-version-fields-a-1
  $ git log --graph --pretty=format:'%s%d'
  * unmatched-name-version-fields-a-1 (HEAD -> new-branch-2)
  * a-1

Test presence of unnecessary fields in a-1.0.0.2 package

  $ revdeps_prototype lint -r . a-1.0.0.2
  Linting a-1.0.0.2 in $TESTCASE_ROOT/. ...
  Error in a-1.0.0.2: The field 'name' that doesn't match its context. Field 'name' has value 'b-1' but was expected of value 'a-1'.
  Error in a-1.0.0.2: The field 'version' that doesn't match its context. Field 'version' has value '0.0.1' but was expected of value '0.0.2'.
  [1]

Setup repo for unexpected file

  $ git reset -q --hard HEAD~1
  $ git apply "patches/a-1-unexpected-file.patch"
  $ git add .
  $ git commit -qm unexpected-file-a-1
  $ git log --graph --pretty=format:'%s%d'
  * unexpected-file-a-1 (HEAD -> new-branch-2)
  * a-1

Test presence of unexpected files in a-1.0.0.2 package

  $ revdeps_prototype lint -r . a-1.0.0.2
  Linting a-1.0.0.2 in $TESTCASE_ROOT/. ...
  Error in a-1.0.0.2: Unexpected file in packages/a-1/a-1.0.0.2/files
  [1]

Setup repo for Forbidden perm file

  $ git reset -q --hard HEAD~1
  $ chmod 500 packages/a-1/a-1.0.0.2/opam
  $ git add .
  $ git commit -qm forbidden-perm-file-a-1
  $ git log --graph --pretty=format:'%s%d'
  * forbidden-perm-file-a-1 (HEAD -> new-branch-2)
  * a-1

Test presence of unexpected files in a-1.0.0.2 package

  $ revdeps_prototype lint -r . a-1.0.0.2
  Linting a-1.0.0.2 in $TESTCASE_ROOT/. ...
  Error in a-1.0.0.2: Forbidden permission for file packages/a-1/a-1.0.0.2/opam. All files should have permissions 644.
  [1]
