local M = {}

local did_setup = false
local did_icons = false

local function setup_icons()
    if did_icons then
        return
    end
    did_icons = true

    local ok, mini_icons = pcall(require, "mini.icons")
    if not ok then
        return
    end

    mini_icons.setup({})
    pcall(mini_icons.mock_nvim_web_devicons)
end

function M.setup()
    if did_setup then
        return
    end
    did_setup = true

    vim.pack.add({
        "https://github.com/nvim-mini/mini.icons",
        "https://github.com/stevearc/oil.nvim",
    })
    setup_icons()
    require("oil").setup({
        default_file_explorer = true,
        skip_confirm_for_simple_edits = true,
        columns = {
            "icon",
        }
    })
end

function M.open()
    M.setup()
    vim.cmd("Oil")
end

return M
