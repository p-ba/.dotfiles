local M = {}

local snacks
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
    -- Many pickers/plugins expect nvim-web-devicons. Provide a compatibility layer.
    pcall(mini_icons.mock_nvim_web_devicons)
end

local function get_snacks()
    if snacks then
        return snacks
    end
    vim.pack.add({
        "https://github.com/nvim-mini/mini.icons",
        "https://github.com/folke/snacks.nvim",
    })
    setup_icons()
    snacks = require("snacks")
    return snacks
end

function M.setup_keymaps()
    vim.keymap.set({ "n" }, "<leader><space>", function()
        get_snacks().picker.smart({
            hidden = true,
            ignored = true,
        })
    end, { silent = true, noremap = true })
    vim.keymap.set({ "n" }, "<leader>r", function()
        get_snacks().picker.lsp_symbols()
    end, { silent = true, noremap = true })
    vim.keymap.set({ "n" }, "<leader>t", function()
        get_snacks().picker.lsp_workspace_symbols()
    end, { silent = true, noremap = true })
    vim.keymap.set({ "n" }, "<leader>b", function()
        get_snacks().picker.buffers()
    end, { silent = true, noremap = true })
    vim.keymap.set({ "n" }, "<leader>f", function()
        get_snacks().picker.resume({ source = "grep" })
    end, { silent = true, noremap = true })
    vim.keymap.set({ "n" }, "<leader>e", function()
        get_snacks().picker.recent()
    end, { silent = true, noremap = true })
    vim.keymap.set({ "n" }, "<leader>/", function()
        get_snacks().explorer()
    end, { silent = true, noremap = true })
end

return M
