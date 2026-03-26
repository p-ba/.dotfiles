local M = {}

local did_setup = false

function M.setup()
    if did_setup then
        return
    end
    did_setup = true

    vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })

    local capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
        textDocument = {
            completion = {
                completionItem = {
                    -- insertReplaceSupport = false,
                },
            },
            foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true
            }
        }
    })

    vim.lsp.config("*", {
        capabilities = capabilities,
    })

    vim.lsp.config("lua_ls", {
        settings = {
            Lua = {
                runtime = {
                    version = 'LuaJIT',
                },
                diagnostics = {
                    globals = { 'vim' },
                },
                workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                    checkThirdParty = false,
                },
                telemetry = {
                    enable = false,
                },
            },
        },
    })

    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user.lsp", {}),
        callback = function(args)
            local format_on_save = { "eslint", "gopls", "lua_ls" }
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client then
                return
            end
            for _, lsp in ipairs(format_on_save) do
                if lsp == client.name and client:supports_method("textDocument/formatting") then
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        group = vim.api.nvim_create_augroup("user.lsp", { clear = false }),
                        buffer = args.buf,
                        callback = function()
                            vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
                        end,
                    })
                end
            end
            if client:supports_method("textDocument/completion") then
                vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = false })
            end
        end,
    })

    vim.api.nvim_create_autocmd("LspDetach", {
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client then
                return
            end
            if client:supports_method("textDocument/formatting") then
                vim.api.nvim_clear_autocmds({
                    event = "BufWritePre",
                    buffer = args.buf,
                })
            end
        end,
    })
end

return M
