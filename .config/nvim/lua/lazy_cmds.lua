local M = {}

function M.setup()
    -- Fugitive: load when an ex-command is invoked (even before a file is opened).
    vim.api.nvim_create_autocmd("CmdUndefined", {
        group = vim.api.nvim_create_augroup("user.fugitive", {}),
        pattern = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "Gclog", "Gblame" },
        callback = function()
            vim.pack.add({ "https://github.com/tpope/vim-fugitive" })
        end,
    })

    -- Keep vinegar available, but don't load it eagerly.
    vim.api.nvim_create_autocmd("CmdUndefined", {
        group = vim.api.nvim_create_augroup("user.vinegar", {}),
        pattern = { "Explore", "Sexplore", "Vexplore", "Texplore" },
        callback = function()
            vim.pack.add({ "https://github.com/tpope/vim-vinegar" })
        end,
    })
end

return M

