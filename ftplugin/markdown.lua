local maps = vim.keymap.set
local opts = {silent=true, noremap=true, buffer=0}
maps("n", "<F5>", function() require'docgenerator'.genseance("doc")end, opts)
maps("n", "<F6>", ":! libreoffice %:p:r.odt & disown<CR><CR>", opts)
