local function ripgrep_search(pattern, options)
    -- Default options.
    options = options or {}
    local file_pattern = options.file_pattern or ""
    local extra_args = options.extra_args or {}
    local cwd = options.cwd or vim.fn.getcwd()

    -- Check if ripgrep is available
    if vim.fn.executable("rg") == 0 then
        vim.notify("ripgrep (rg) is not installed or not in PATH", vim.log.levels.WARN)
        return nil
    end

    -- Construct the ripgrep command.
    local cmd = {
        "rg",
        "--vimgrep",
        "--color=never",
        "--no-messages",
        "-U",
        string.format("'%s'", pattern),
        file_pattern,
    }

    -- Add extra arguments.
    for _, arg in ipairs(extra_args) do
        table.insert(cmd, arg)
    end
    table.insert(cmd, cwd)

    -- Execute the ripgrep command.
    local handle = io.popen(table.concat(cmd, " "))
    if not handle then
        vim.notify("Failed to execute ripgrep.", vim.log.levels.ERROR)
        return nil
    end

    local output = handle:read("*a")
    handle:close()
    
    if not output or output == "" then
        return {}
    end

    -- Parse the output.
    local results = {}
    for line in output:gmatch("[^\n]+") do
        local filename, line_num, column, text = line:match("([^:]+):(%d+):(%d+):(.*)")
        if filename then
            table.insert(results, {
                filename = string.gsub(filename, cwd .. "/", ""),
                lnum = tonumber(line_num),
                col = tonumber(column),
                text = text,
                type = "F",
                user_data = text,
            })
        end
    end

    return results
end

local catch_all_regex = "[\\s.]<cword>[\\s\\n{(=]"

local js_ts_regex = "((type|interface|class|enum)\\s<cword>[\\s{(:])|\\s<cword>(\\s*\\(|\\s*=\\s*[f\\(])"

local regex_override = {
    go = "(func|type)(\\s*\\(.*\\))?\\s*<cword>.*[\\s({]",
    py = "(def|class)\\s*<cword>[\\s\\n(]",
    js = js_ts_regex,
    ts = js_ts_regex,
    php = "(class|interface|enum|function|const)\\s*<cword>[\\s\\n{(]",
    cs = "(public|private|protected|abstract|class|enum)(\\s\\w*)?(\\s[\\w<>]*)?\\s<cword>[\\n\\s{:]"
}

function dumbjump_tagfunc(tag_name, flags)
    -- `tag_name`: The tag to search for.
    -- `flags`: Tag search flags (e.g., 'w' for wrap search).
    -- `...`: Additional arguments (e.g., context).
    if not tag_name or tag_name == "" then
        return {}
    end
    
    if string.find(flags, "r") or string.find(flags, "i") then
        return nil
    end
    local results = {}

    local ext = vim.fn.expand("%:e")
    local file_pattern = nil
    if ext and ext ~= "" then
        file_pattern = "*." .. ext
    end

    local regex = catch_all_regex
    if ext and regex_override[ext] then
        regex = regex_override[ext]
    end
    regex = string.gsub(regex, "<cword>", vim.fn.escape(tag_name, "[]().*+?^$"))

    local search_results = ripgrep_search(regex, {
        file_pattern = file_pattern,
        extra_args = { "--ignore-case" }
    })

    if search_results and #search_results > 0 then
        local num_results = 0
        for _, result in ipairs(search_results) do
            num_results = num_results + 1
            table.insert(results, {
                name = tag_name,
                text = result.text,
                filename = result.filename,
                cmd = ":" .. result.lnum,
                lnum = result.lnum,
                kind = "f",
                user_data = result.text,
            })
        end

        if num_results > 1 then
            vim.schedule(function()
                vim.fn.setqflist({})
                vim.fn.setqflist(search_results, "a")
                vim.cmd("copen")
            end)
        end
    end


    return results
end

-- Set the custom tagfunc.
vim.o.tagfunc = "v:lua.dumbjump_tagfunc"

-- Let the LSP hijack the tagfunc, if supported
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end
        if client:supports_method('textDocument/definition') then
            vim.o.tagfunc = "v:lua.vim.lsp.tagfunc"
        end
    end,
})

vim.api.nvim_create_autocmd('LspDetach', {
    callback = function()
        vim.o.tagfunc = "v:lua.dumbjump_tagfunc"
    end,
})
