require("settings")
require("keymaps")
require("lazy_cmds").setup()

-- Keep startup minimal; defer heavier modules/plugins.
vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        require("theme").setup()
        require("tagfunc")
    end,
})

-- LSP: load once we actually open a file buffer.
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    once = true,
    callback = function()
        require("lsp").setup()

        if vim.fn.filereadable(vim.fn.stdpath("config") .. "/lua/_local_lsp.lua") == 1 then
            require("_local_lsp")
        end
    end,
})

-- Markdown: only load for markdown buffers.
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown" },
    callback = function()
        require("markdown").setup()
    end,
})

-- Misc plugin glue: load after UI is ready, but still lazily.
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    once = true,
    callback = function()
        require("misc").setup()
    end,
})
