local M = {}

local did_setup = false

local function once(fn)
    local done = false
    local result
    return function(...)
        if done then
            return result
        end
        result = fn(...)
        done = true
        return result
    end
end

function M.setup()
    if did_setup then
        return
    end
    did_setup = true

    -- Comment.nvim: enable once you start editing.
    vim.pack.add({ "https://github.com/numToStr/Comment.nvim" })
    require("Comment").setup()

    -- LuaSnip: only load on first snippet interaction (keymaps).
    local load_luasnip = once(function()
        vim.pack.add({
            "https://github.com/L3MON4D3/LuaSnip",
            "https://github.com/rafamadriz/friendly-snippets",
        })
        local ls = require("luasnip")
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_lua").lazy_load({ paths = "~/.config/nvim/LuaSnip/" })
        return ls
    end)

    vim.keymap.set({ "i", "s" }, "<C-e>", function()
        local ls = load_luasnip()
        if ls then
            ls.expand()
        end
    end, { silent = true, noremap = true })

    vim.keymap.set({ "i", "s" }, "<C-n>", function()
        local ls = load_luasnip()
        if ls and ls.jumpable(1) then
            ls.jump(1)
        end
    end, { silent = true })

    vim.keymap.set({ "i", "s" }, "<C-p>", function()
        local ls = load_luasnip()
        if ls and ls.jumpable(-1) then
            ls.jump(-1)
        end
    end, { silent = true })

    -- Undotree: load only when toggled.
    vim.keymap.set({ "n" }, "<leader>u", function()
        vim.pack.add({ "https://github.com/mbbill/undotree" })
        vim.cmd("UndotreeToggle")
    end, { silent = true, noremap = true })

    -- Emmet: load only for relevant filetypes.
    vim.g.user_emmet_leader_key = "<C-x>"
    vim.g.user_emmet_settings = {
        blade = {
            extends = "html",
        },
    }
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user.emmet", {}),
        pattern = { "html", "css", "scss", "javascriptreact", "typescriptreact", "blade", "php" },
        callback = function()
            vim.pack.add({ "https://github.com/mattn/emmet-vim" })
        end,
    })
end

return M
