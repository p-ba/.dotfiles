require("_init")
require("settings")
require("keymaps")
require("theme")

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        require("tagfunc")
        require("picker")
        require("lsp")
        require("misc")
        require("oil_config")
        require("markdown")
        if vim.fn.filereadable(vim.fn.stdpath("config") .. "/lua/_local_lsp.lua") == 1 then
            require("_local_lsp")
        end
    end,
})
