vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "[J|j]enkinsfile*" },
    callback = function()
        vim.opt_local.filetype = "groovy"
    end,
})
