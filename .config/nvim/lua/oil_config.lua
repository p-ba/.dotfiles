local M = {}

local did_setup = false
local did_icons = false
local always_hidden_names = {
    [".DS_Store"] = true,
    [".build"] = true,
    [".cache"] = true,
    [".direnv"] = true,
    [".git"] = true,
    [".hg"] = true,
    [".jj"] = true,
    [".swiftpm"] = true,
    [".svn"] = true,
    ["build"] = true,
    ["node_modules"] = true,
}

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
        },
        view_options = {
            show_hidden = true,
            is_always_hidden = function(name, _)
                return always_hidden_names[name] == true
            end,
        },
    })
end

function M.open()
    M.setup()
    vim.cmd("Oil")
end

return M
