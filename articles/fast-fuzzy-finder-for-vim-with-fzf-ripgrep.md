# Fast Fuzzy Finder for Vim with fzf and ripgrep

[fzf](https://github.com/junegunn/fzf) is a lightning fast command-line fuzzy finder that runs asynchronously and can be integrated to vim to search for files, file contents and much more.

## Setting up fzf in Vim

fzf has an official Vim plugin which can be installed with any Vim plugin manager. We can install fzf with [vim-plug](https://github.com/junegunn/vim-plug) by adding this to our `.vimrc`, inside the plugin manager call and by running `:PlugInstall`.

```
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
```

### Useful fzf commands that work out of the box

<table>
<thead>
<tr>
<th>Command</th>
<th>List</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>:Files [PATH]</code></td>
<td>Files (runs <code>$FZF_DEFAULT_COMMAND</code> if defined)</td>
</tr>
<tr>
<td><code>:GFiles [OPTS]</code></td>
<td>Git files (<code>git ls-files</code>)</td>
</tr>
<tr>
<td><code>:GFiles?</code></td>
<td>Git files (<code>git status</code>)</td>
</tr>
<tr>
<td><code>:Buffers</code></td>
<td>Open buffers</td>
</tr>
<tr>
<td><code>:Rg [PATTERN]</code></td>
<td><a href="https://github.com/BurntSushi/ripgrep">rg</a> search result (<code>ALT-A</code> to select all, <code>ALT-D</code> to deselect all)</td>
</tr>
<tr>
<td><code>:Tags [QUERY]</code></td>
<td>Tags in the project (<code>ctags -R</code>)</td>
</tr>
<tr>
<td><code>:Marks</code></td>
<td>Marks</td>
</tr>
<tr>
<td><code>:Windows</code></td>
<td>Windows</td>
</tr>
<tr>
<td><code>:Snippets</code></td>
<td>Snippets (<a href="https://github.com/SirVer/ultisnips">UltiSnips</a>)</td>
</tr>
</tbody>
</table>

| Command           | List                                                                                                                    |
| ---               | ---                                                                                                                     |
| `:Files [PATH]`   | Files (runs `$FZF_DEFAULT_COMMAND` if defined)                                                                          |
| `:GFiles [OPTS]`  | Git files (`git ls-files`)                                                                                              |
| `:GFiles?`        | Git files (`git status`)                                                                                                |
| `:Buffers`        | Open buffers                                                                                                            |
| `:Rg [PATTERN]`   | [rg](https://github.com/BurntSushi/ripgrep) search result (`ALT-A` to select all, `ALT-D` to deselect all)              |
| `:Tags [QUERY]`   | Tags in the project (`ctags -R`)                                                                                        |
| `:Marks`          | Marks                                                                                                                   |
| `:Windows`        | Windows                                                                                                                 |
| `:History`        | `v:oldfiles` and open buffers                                                                                           |
| `:History:`       | Command history                                                                                                         |
| `:History/`       | Search history                                                                                                          |
| `:Snippets`       | Snippets ([UltiSnips](https://github.com/SirVer/ultisnips))                                                             |
| `:Commands`       | Commands                                                                                                                |

## Integrating ripgrep with fzf

By default fzf uses the find command to walk through a file hierarchy to locate files based on a search criteria. However, fzf supports other similar search tools such as [fd](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep) or [the silver searcher](https://github.com/ggreer/the_silver_searcher) for creating a list of files to traverse through. My preferred search tool to use is ripgrep. ripgrep is a fast line-oriented search tool that recursively searches the current directory for a regex pattern. ripgrep also automatically respects rules defined in `.gitignore`, `.ignore`, and `.rgignore` for cleaner search results.

We can override the default fzf find command by defining `FZF_DEFAULT_COMMAND` in our environment. The easiest way to do this is by setting it in our `.bashrc`:

```sh
export FZF_DEFAULT_COMMAND='rg --files --ignore-vcs --hidden'
```

This command passes three options to ripgrep to make ripgrep print the output of files including hidden files while respecting rules set in `.gitignore`.

Now if we call `:Files` in vim we should see a list of files based on the search results from `rg --files --ignore-vcs --hidden`.

We can also use ripgrep to interactively search for file contents. Fzf supports this behaviour out of the box with the command `:Rg`.

## File previews with fzf inside Vim

It is very helpful to have file previews enabled in order to find the right file with fzf. This can be achieved by redefining the default fzf commands in our `.vimrc`:

```
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)
command! -bang -nargs=? -complete=dir GFiles
    \ call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(), <bang>0)
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)
```

Now if we call `:Files`, `:GFiles`, or `:Rg` and make our search, we can see file previews.

### Syntax highlighting

By default fzf uses the `cat` command to show the file previews, but if we are mostly working on code we might want to also see some syntax highlighting in our file previews. Luckily fzf supports this out of the box with an external program [bat](https://github.com/sharkdp/bat). All we need to do is to install it and fzf automatically uses it over `cat`.
