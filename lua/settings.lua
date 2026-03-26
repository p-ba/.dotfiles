if vim.g.neovide then
    vim.g.neovide_opacity = 0.9
    vim.g.transparency = 0.8
    vim.o.background = "dark"
else
    require('vim._core.ui2').enable({})
end
vim.opt.linespace = 12
vim.o.guifont = "JetBrainsMono Nerd Font:h16"
vim.g.netrw_liststyle = 3
vim.g.mapleader = " "
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 40
vim.opt.grepprg = "rg --vimgrep -U"
vim.opt.guicursor = "n-v-c-i:block"
vim.opt.winborder = "rounded"
vim.g.editorconfig = true

-- Align <?php / ?> with surrounding HTML (see :help php-indent, PHP_outdentphpescape).
vim.g.PHP_outdentphpescape = 0
-- Unused when |indentexpr| is tree-sitter (see lua/php_indent.lua); kept for Vim fallback.
vim.g.PHP_autoformatcomment = 0

vim.diagnostic.config({
    virtual_text = true
})

vim.api.nvim_create_user_command('TrimWhitespace', function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd(":%s/\\s\\+$//e")
    vim.fn.setpos(".", save_cursor)
end, { nargs = 0, desc = "Remove trailing whitespace" })

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    pattern = { "*.scss" },
    command = "set filetype=css",
})

vim.opt.path:append("**")
vim.opt.wildignore:append {
    "node_modules/**",
    "vendor/**",
    "var/cache/**",
    "venv/**",
    ".venv/**",
    ".git/**",
    "**/*.min.js",
    "**/*.min.css",
    "**/*.css.min",
    "**/*.js.min",
    "**/*.css.map",
    "**/*.js.map",
    "**/*.jpg",
    "**/*.jpeg",
    "**/*.png",
    "**/*.gif",
    "**/*.zip",
    "**/*.gz",
}

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.backspace = 'indent,eol,start'
vim.opt.completeopt = { "menuone", "noselect", "noinsert", "preview" }
vim.opt.shortmess:append "c"

vim.opt.wrap = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.iskeyword:append('-')
vim.opt.iskeyword:append('$')

vim.opt.clipboard:append('unnamedplus')

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv('HOME') .. '/.config/nvim/undodir'
vim.opt.undofile = true

vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = ""

-- Better search experience
vim.opt.showmatch = true
vim.opt.matchtime = 1

-- Better file handling
vim.opt.autoread = true
vim.opt.autowrite = false
