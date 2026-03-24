vim.pack.add({ "https://github.com/L3MON4D3/LuaSnip" })
vim.pack.add({ "https://github.com/rafamadriz/friendly-snippets" })

local ls = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_lua").lazy_load({ paths = "~/.config/nvim/LuaSnip/" })

vim.keymap.set({ "i", "s" }, "<C-e>", function()
    ls.expand()
end, { silent = true, noremap = true })

vim.keymap.set({ "i", "s" }, "<C-n>", function()
    if ls.jumpable(1) then
        ls.jump(1)
    end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-p>", function()
    if ls.jumpable(-1) then
        ls.jump(-1)
    end
end, { silent = true })

vim.pack.add({ "https://github.com/mbbill/undotree" })
vim.keymap.set({ "n" }, "<leader>u", function()
    vim.cmd("UndotreeToggle")
end, { silent = true, noremap = true })

vim.pack.add({ "https://github.com/tpope/vim-fugitive" })
vim.g.user_emmet_leader_key = "<C-x>"
vim.g.user_emmet_settings = {
    blade = {
        extends = "html",
    },
}
vim.pack.add({ "https://github.com/mattn/emmet-vim" })
vim.pack.add({ "https://github.com/numToStr/Comment.nvim" })
require("Comment").setup()
vim.pack.add({ "https://github.com/tpope/vim-vinegar" })
