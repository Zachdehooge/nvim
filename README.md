# NVCHAD Config
  - Install Rust Compiler
  - Run Mason Install All after rust compiler is installed

## Commands
* `<leader>xx` - TodoTelescope
* `<SHIFT>v` - select whole line
* `y` - copy
* `p` - paste
* `u` - undo
* `<C-r>` - redo
* `:%s/old_text/new_text` - find and replace (add a `.` before or after the text to encompass the space)
* `/` - find
* `f5` - overseertoggle
* `f6` - overseerrun
* `:%s/old_word/new_word/g` - find and replace all
  
![image](https://github.com/user-attachments/assets/dbbcb367-464f-4407-b89f-83e79b6be0ee)

---

## Character & Line Motions

| Motion | Description |
|--------|-------------|
| `h`    | Move left |
| `l`    | Move right |
| `j`    | Move down |
| `k`    | Move up |
| `0`    | Move to beginning of line |
| `^`    | Move to first non-blank character of line |
| `$`    | Move to end of line |
| `g_`   | Move to last non-blank character of line |

---

## Word Motions

| Motion | Description |
|--------|-------------|
| `w`    | Move to beginning of next word (word = letters, digits) |
| `W`    | Move to next WORD (WORD = anything not whitespace) |
| `e`    | Move to end of word |
| `E`    | Move to end of WORD |
| `b`    | Move to beginning of previous word |
| `B`    | Move to beginning of previous WORD |
| `ge`   | Move to end of previous word |
| `gE`   | Move to end of previous WORD |

---

## Paragraph & Sentence Motions

| Motion | Description |
|--------|-------------|
| `{`    | Move to beginning of previous paragraph |
| `}`    | Move to beginning of next paragraph |
| `(`    | Move back a sentence |
| `)`    | Move forward a sentence |

---

## Scrolling

| Motion | Description |
|--------|-------------|
| `Ctrl-d` | Scroll down half a screen |
| `Ctrl-u` | Scroll up half a screen |
| `Ctrl-f` | Scroll forward one screen |
| `Ctrl-b` | Scroll back one screen |
| `zz`     | Center cursor line |
| `zt`     | Move current line to top |
| `zb`     | Move current line to bottom |

---

## Search Motions

| Motion | Description |
|--------|-------------|
| `/pattern` | Search forward for "pattern" |
| `?pattern` | Search backward for "pattern" |
| `n`        | Repeat last search forward |
| `N`        | Repeat last search backward |
| `*`        | Search forward for word under cursor |
| `#`        | Search backward for word under cursor |
| `g*`       | Search forward for partial word |
| `g#`       | Search backward for partial word |

---

## Mark and Jump Motions

| Motion | Description |
|--------|-------------|
| `'a`   | Jump to beginning of line of mark `a` |
| `` `a `` | Jump to exact cursor position of mark `a` |
| `''`   | Jump to line before last jump |
| `` `` `` | Jump to exact position before last jump |
| `gg`   | Go to beginning of file |
| `G`    | Go to end of file |
| `:n`   | Go to line `n` |
| `%`    | Jump to matching bracket `()`, `{}`, `[]` |

---

## Visual Line/Block Motions

| Motion | Description |
|--------|-------------|
| `V`       | Start visual line selection |
| `Ctrl-v`  | Start visual block selection |
| `gv`      | Reselect last visual selection |

---

## Miscellaneous Motions

| Motion | Description |
|--------|-------------|
| `H`    | Move to top of screen |
| `M`    | Move to middle of screen |
| `L`    | Move to bottom of screen |
| `g0` / `g^` | Start of display line |
| `g$`   | End of display line |