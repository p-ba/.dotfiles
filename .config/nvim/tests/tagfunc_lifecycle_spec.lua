local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. (": expected %s, got %s"):format(expected, actual), 2)
    end
end

local script_path = debug.getinfo(1, "S").source:sub(2)
local config_root = script_path:match("(.+)/tests/") or "."
package.path = config_root .. "/lua/?.lua;" .. package.path

require("tagfunc")

local original_get_client_by_id = vim.lsp.get_client_by_id
local original_get_clients = vim.lsp.get_clients
local clients_by_id = {}
local clients_by_buffer = {}

vim.lsp.get_client_by_id = function(id)
    return clients_by_id[id]
end
vim.lsp.get_clients = function(options)
    return clients_by_buffer[options.bufnr] or {}
end

local function definition_client(id)
    return {
        id = id,
        supports_method = function(_, method)
            return method == "textDocument/definition"
        end,
    }
end

local go_buffer = vim.api.nvim_create_buf(false, true)
local other_buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(other_buffer)

local first_client = definition_client(1)
local second_client = definition_client(2)
clients_by_id[first_client.id] = first_client
clients_by_id[second_client.id] = second_client
clients_by_buffer[go_buffer] = { first_client, second_client }

vim.api.nvim_exec_autocmds("LspAttach", {
    buffer = go_buffer,
    data = { client_id = first_client.id },
})
assert_equal(vim.bo[go_buffer].tagfunc, "v:lua.filtered_lsp_tagfunc", "attached buffer tagfunc")
assert_equal(vim.bo[other_buffer].tagfunc, "v:lua.dumbjump_tagfunc", "unrelated buffer tagfunc")

vim.api.nvim_exec_autocmds("LspDetach", {
    buffer = go_buffer,
    data = { client_id = first_client.id },
})
assert_equal(vim.bo[go_buffer].tagfunc, "v:lua.filtered_lsp_tagfunc", "remaining client retains tagfunc")

clients_by_buffer[go_buffer] = { second_client }
vim.api.nvim_exec_autocmds("LspDetach", {
    buffer = go_buffer,
    data = { client_id = second_client.id },
})
assert_equal(vim.bo[go_buffer].tagfunc, "v:lua.dumbjump_tagfunc", "last detach restores tagfunc")

vim.lsp.get_client_by_id = original_get_client_by_id
vim.lsp.get_clients = original_get_clients
