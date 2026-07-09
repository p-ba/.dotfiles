local M = {}

local did_setup = false

function M.setup()
    if did_setup then
        return
    end
    did_setup = true

    -- Colorscheme
    vim.pack.add({ "https://github.com/folke/tokyonight.nvim" })

    -- Treesitter (lazy-start per FileType)
    vim.pack.add({
        {
            src = "https://github.com/nvim-treesitter/nvim-treesitter",
            version = "main",
        }
    })
    require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
    })
    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
            local buf = args.buf
            local ft = vim.bo[buf].filetype
            local lang = vim.treesitter.language.get_lang(ft)
            if not lang or lang == "" then
                return
            end
            if vim.treesitter.language.add(lang) then
                vim.treesitter.start(buf, lang)
            end
        end,
    })

    if os.getenv("TERM_PROGRAM") == "Apple_Terminal" then
        pcall(function()
            vim.cmd("colorscheme catppuccin")
        end)
        vim.opt.termguicolors = false
    else
        local transparent = true
        vim.opt.termguicolors = true
        require("tokyonight").setup({
            style = "moon",
            transparent = transparent,
            styles = {
                sidebars = transparent and "transparent" or "moon",
                floats = transparent and "transparent" or "moon",
            },
            on_colors = function(colors)
                colors.bg_dark = transparent and colors.none or colors.bg_dark
                colors.bg_sidebar = transparent and colors.none or colors.bg_sidebar
                colors.bg_statusline = transparent and colors.none or colors.bg_statusline
            end,
        })
        vim.cmd([[colorscheme tokyonight]])
    end
end

return M
