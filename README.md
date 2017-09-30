# `apt-sources-list`

This Emacs package contains a major mode for editing APT’s `.list` files.

The `/etc/apt/sources.list` file and other files in
`/etc/apt/sources.list.d` tell APT, found on Debian-based systems and
others, where to find packages for installation.

This format specifies a package source with a single line, e.g.:

    deb http://deb.debian.org/debian stable main contrib

For more information about the format you can read the manual
pages [apt(8)][] and [sources.list(5)][].

This mode is derived from `apt-sources-mode` distributed in the
`debian-el` Debian package, but has many differences. Among them:

- The load hook has been removed. Use `with-eval-after-load`.
- What is properly called a “suite” is no longer called a “distribution.”
- Most keys have changed. This is for better mnemonics (`C-c C-s` to
  change the suite), or for better Emacs integration (`C-M-n` or your
  `forward-list` equivalent to move between source lines).
- Editing functions may be called more easily from Emacs Lisp.


## License

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.


[apt(8)]: https://manpages.debian.org/stable/apt/sources.list.5.en.html
[sources.list(5)]: https://manpages.debian.org/stable/apt/sources.list.5.en.html
