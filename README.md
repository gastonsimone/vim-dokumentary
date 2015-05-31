# dokumentary.vim

## About

Dokumentary improves what the `K` command does in Vim by customizing its
behaviour, depending on the type of file you are editing.

Vim's standard `K` command for normal mode let's us easily run a program to
lookup the keyword under the cursor. The program to run can be customized with
the `keywordprg` (`kp`) option, whose default option is `man`.

This presents two problems:

1. The `man` command is the right choice only if you are writing a shell
   script or C code.
2. Vim only runs that command and wait for it to finish to continue using
   Vim, which sometimes it is not the ideal, because you would like to see
   that documentation at the same time you are editing your file.

Dokumentary solves these two issues by doing the following:

1. It creates buffer-specific mappings for `K` and `Visual-K`, depending on
   the type of file you are editing. See the supported file types below.
2. It loads the retireved documentation in a vim window, so you can see
   the documentation together with your file and use all the Vim power to
   search and copy from it.
3. The default command is not `man`, but a system-specific dictionary. So
   if you are just reading plain text, `K` will show the definition of the
   word under the cursor.

## Supported file types

Currently Dokumentary supports these file types:

| File type  | Documentation program                  |
| ---------  | -------------------------------------- |
| C          | man                                    |
| C++        | man                                    |
| go         | godoc                                  |
| Makefiles  | man                                    |
| perl       | perldoc                                |
| Plain text | dict, sdvc or Mac OS X Dictionary app. |
| python     | pydoc                                  |
| sh         | man                                    |
| TeX/LaTeX  | texdoc                                 |
| Vimscript  | :help                                  |
| Vim help   | :help                                  |
| Yacc       | man                                    |

## Mappings

Dokumentary only maps `K` in Normal and Visual modes.

## Behavior

### Windows

As described in the introduction, Dokumentary shows the documentation in a Vim
window. This window has `buftype=nofile` and `bufhidden=delete`.

This special buffer also gets mappings for `K`, so it is very simple to
_navigate_ through the documentation by pressing `K` in it. Every word becomes
a potential link!

As a side effect of how Dokumentary is implemented, pressing `u` in normal
mode (undo) in one of these buffers behaves like _going back_ to the
previous documentation page.

### Man as documentation program

When using "`man`" as the documentation program, Dokumentary understands section
references. For example, if the cursor is over

```
printf(3)
```

and you press `K` in Normal mode, Dokumentary will load the documentation
for `printf` under section 3.

### Visual mode

You can select more than one word in Visual mode and press `K`. Dokumentary
will use all the selected text as the keyword for the corresponding
documentation program.

Careful! Some documentation programs will not work with more than one word.
The result may be unexpected in some cases.

## Configuration

### man2html

Dokumentary understands the global, boolean variable `g:dokumentary_man2html`.
When it is set to true and the command `man2html` is available in the system,
it will redirect the man output to a temporary file in HTML format and open it
in the system's default browser. By default this variable is undefined.

**NOTE:** The underlying system must support the `open` command in the same way
Mac OS X does. This is the method used to open the temporary HTML file in the
default browser.

## TO DO

1. Simplify the process of adding more supported file types.
   It would be easier if `autocmd` allowed to define the pattern from
   a variable.
2. Add public commands so the user can add support for more file types.
   Something like:
   ```
   Dok[ument] c "mycdoc -s {0}"
   ```
3. Vim's standard `K` command supports a count before `K` to specify the
   specific manual page to show when the documentation program being used
   is `man`. For completeness this should be included. I could not find an
   easy way to do this.

# License

Distributed under the same terms as Vim itself. See `:help license`.

