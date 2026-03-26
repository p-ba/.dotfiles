local M = {}

local did_setup = false

function M.setup()
    if did_setup then
        return
    end
    did_setup = true

    vim.pack.add({
        "https://github.com/nvim-mini/mini.icons",
        "https://github.com/MeanderingProgrammer/render-markdown.nvim",
    })

    require("mini.icons").setup({})
    require("render-markdown").setup({})
end

return M
