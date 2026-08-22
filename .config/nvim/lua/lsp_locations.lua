local M = {}

local generated_go_patterns = {
    "/generated/",
    "/app/api/graphql/graph/",
    "%.gen%.go$",
    "_mock%.go$",
}

local function has_generated_header(filename)
    local file = io.open(filename, "r")
    if not file then
        return false
    end

    for _ = 1, 20 do
        local line = file:read("*l")
        if not line then
            break
        end
        if line:match("^// Code generated .* DO NOT EDIT%.$") then
            file:close()
            return true
        end
    end

    file:close()
    return false
end

function M.is_generated_go_file(filename)
    if type(filename) ~= "string" or not filename:match("%.go$") then
        return false
    end

    local normalized = filename:gsub("\\", "/")
    for _, pattern in ipairs(generated_go_patterns) do
        if normalized:match(pattern) then
            return true
        end
    end

    return has_generated_header(filename)
end

function M.filter_items(items)
    local filtered = {}
    local excluded = 0

    for _, item in ipairs(items or {}) do
        local filename = item.filename
        if not filename and item.bufnr and item.bufnr > 0 then
            filename = vim.api.nvim_buf_get_name(item.bufnr)
        end

        if M.is_generated_go_file(filename) then
            excluded = excluded + 1
        else
            table.insert(filtered, item)
        end
    end

    return filtered, excluded
end

local function jump_to_item(item, context)
    local bufnr = item.bufnr
    if not bufnr or bufnr == 0 then
        bufnr = vim.fn.bufadd(item.filename)
    end

    vim.cmd("normal! m'")
    vim.fn.settagstack(context.win, {
        items = { { tagname = context.tagname, from = context.from } },
    }, "t")

    vim.bo[bufnr].buflisted = true
    vim.api.nvim_win_set_buf(context.win, bufnr)
    vim.api.nvim_win_set_cursor(context.win, {
        math.max(item.lnum or 1, 1),
        math.max((item.col or 1) - 1, 0),
    })
    vim.api.nvim_win_call(context.win, function()
        vim.cmd("normal! zv")
    end)
end

local function make_on_list(context)
    return function(list)
        local items, excluded = M.filter_items(list.items)
        if #items == 0 then
            local message = excluded > 0 and "Only generated Go locations found" or "No locations found"
            vim.notify(message, vim.log.levels.INFO)
            return
        end

        if #items == 1 then
            jump_to_item(items[1], context)
            return
        end

        list.items = items
        vim.fn.setqflist({}, " ", list)
        vim.cmd("botright copen")
    end
end

local function request(request_fn)
    local bufnr = vim.api.nvim_get_current_buf()
    local context = {
        from = vim.fn.getpos("."),
        tagname = vim.fn.expand("<cword>"),
        win = vim.api.nvim_get_current_win(),
    }
    context.from[1] = bufnr

    request_fn({ on_list = make_on_list(context) })
end

function M.definition()
    request(vim.lsp.buf.definition)
end

function M.implementation()
    request(vim.lsp.buf.implementation)
end

return M
