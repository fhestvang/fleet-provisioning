-- blink.cmp (LazyVim's completion engine) defaults to a keymap where Tab only
-- jumps snippet placeholders and you accept with Enter / Ctrl-Y. The "super-tab"
-- preset makes Tab select-and-accept the highlighted menu item (and still jump
-- snippets), which is the Tab-to-complete behaviour you want.
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = { preset = "super-tab" },
    },
  },
}
