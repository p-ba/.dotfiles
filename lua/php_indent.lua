local ok_ts, ts_indent = pcall(require, "nvim-treesitter.indent")

---@param bufnr integer
---@return string
local function buf_filetype(bufnr)
  local ok, bo = pcall(function()
    return vim.bo
  end)
  if not ok or bo == nil then
    return ""
  end
  local ft = ""
  if type(bo) == "table" then
    if type(bo[bufnr]) == "table" then
      ft = bo[bufnr].filetype or ""
    else
      ft = bo.filetype or ""
    end
  end
  return ft
end

---Strip a trailing `// ...` comment (PHP) so we can detect `,` / `;` at EOL (spec Case 4).
---@param line string
---@return string
local function strip_trailing_line_comment(line)
  local s = vim.trim(line or "")
  local i = s:find("//", 1, true)
  if i then
    s = vim.trim(s:sub(1, i - 1))
  end
  return s
end

---Multiline block after `<?php` on a line that does not close with `?>` — next line aligns with that tag (spec: mixed HTML/PHP).
---@param prev_line string
---@return boolean
local function continues_after_open_php_tag(prev_line)
  local t = vim.trim(prev_line or "")
  if t == "" or not t:match("^<%?php") then
    return false
  end
  return t:match("%?>") == nil
end

---Next line continues a static call (Foo::bar()) without a terminating ';' (PSR-12 hanging indent).
---@param prev_line string
---@return boolean
local function is_static_call_continuation(prev_line)
  local t = vim.trim(prev_line or "")
  if t == "" or t:match(";%s*$") then
    return false
  end
  return t:match("::%s*%w+%s*%([^)]*%)%s*$") ~= nil
end

---@param line string
---@return boolean
local function opens_indented_block(line)
  local t = vim.trim(line or "")
  return t:match("[%[{(]%s*$") ~= nil
end

---@param line string
---@return boolean
local function continues_list_item(line)
  return strip_trailing_line_comment(line):match(",%s*$") ~= nil
end

---Previous line ends a statement with `;` (possibly before a trailing `//` comment).
---Must not match `];` alone — that closes `$x = [ ... ];` and the next line should dedent (foreach, etc.).
---@param line string
---@return boolean
local function continues_after_statement(line)
  local t = strip_trailing_line_comment(line)
  if t == "" then
    return false
  end
  -- Ternary branch lines (`? ...` / `: ...`) may end with `;` on the final
  -- branch, but the next statement should dedent to the assignment level.
  if t:match("^%?") or t:match("^:") then
    return false
  end
  if t:match("^%]%s*;$") or t:match("^%]%s*%)%s*;$") then
    return false
  end
  return t:match(";%s*$") ~= nil
end

---Current line is a closing token that should align with an outer block, not inherit indent from `prev;`.
---@param line string
---@return boolean
local function looks_like_dedent_line(line)
  local t = strip_trailing_line_comment(line)
  if t == "" then
    return false
  end
  if t:match("^%}%s*$") then
    return true
  end
  if
    t:match("^%]%s*;%s*$")
    or t:match("^%]%s*,%s*$")
    or t:match("^%]%s*%)%s*;%s*$")
    or t:match("^%]%s*%)%s*,%s*$")
  then
    return true
  end
  return false
end

---Line is only a closing `];` for an array assignment (`$x = [ ... ];`).
---@param line string
---@return boolean
local function is_closing_array_bracket_line(line)
  local t = strip_trailing_line_comment(line)
  return t:match("^%]%s*;%s*$") ~= nil or t:match("^%]%s*%)%s*;%s*$") ~= nil
end

---Line is only a closing `]);` for an array passed as a call argument.
---@param line string
---@return boolean
local function is_closing_call_array_bracket_line(line)
  return strip_trailing_line_comment(line):match("^%]%s*%)%s*;%s*$") ~= nil
end

---Line is only a standalone closing bracket: `]` / `],` / `];`.
---@param line string
---@return boolean
local function is_standalone_closing_bracket_line(line)
  -- Also handle `]);` (array literal passed to a call).
  return strip_trailing_line_comment(line):match("^%]%s*%)*%s*[,;]?%s*$") ~= nil
end

---@param bufnr integer
---@param from_lnum integer
---@return integer|nil
local function indent_of_array_assignment_open(bufnr, from_lnum)
  for lnum = from_lnum - 1, 1, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local t = vim.trim(l)
    if t:match("^%$[%w_]+%s*=%s*%[") then
      return vim.fn.indent(lnum)
    end
  end
  return nil
end

---@param bufnr integer
---@param from_lnum integer
---@return integer|nil
local function indent_of_array_item_open(bufnr, from_lnum)
  for lnum = from_lnum - 1, 1, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local t = vim.trim(l)
    -- Match: 'nested_array' => [
    if t:match("=>%s*%[%s*$") then
      return vim.fn.indent(lnum)
    end
    -- Don't cross array assignment boundary; the first `$x = [` above is the outermost relevant anchor.
    if t:match("^%$[%w_]+%s*=%s*%[") then
      return nil
    end
  end
  return nil
end

---@param bufnr integer
---@param from_lnum integer
---@return integer|nil
local function indent_of_array_open(bufnr, from_lnum)
  for lnum = from_lnum - 1, 1, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local t = vim.trim(l)
    -- Match any array opener that ends the line, including:
    -- - assignment: $x = [
    -- - item: 'k' => [
    -- - call arg: foo(
    --             [
    if t:match("%[%s*$") then
      return vim.fn.indent(lnum)
    end
  end
  return nil
end

---@param bufnr integer
---@param from_lnum integer
---@return integer|nil
local function indent_of_call_array_open(bufnr, from_lnum)
  for lnum = from_lnum - 1, 1, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local t = vim.trim(l)
    -- Match: foo([  OR  foo( [  OR  return view('x', [
    if t:match("%(%s*%[%s*$") then
      return vim.fn.indent(lnum)
    end
  end
  return nil
end

---@param line string
---@return boolean
local function is_closing_call_paren_line(line)
  return strip_trailing_line_comment(line):match("^%)%s*;%s*$") ~= nil
end

---@param line string
---@return boolean
local function is_closing_block_paren_line(line)
  return strip_trailing_line_comment(line):match("^%)%s*{%s*$") ~= nil
end

---@param line string
---@return boolean
local function starts_with_logical_operator(line)
  local t = strip_trailing_line_comment(line)
  return t:match("^||") ~= nil or t:match("^&&") ~= nil
end

---@param line string
---@return boolean
local function starts_with_ternary_operator(line)
  local t = strip_trailing_line_comment(line)
  return t:match("^%?") ~= nil or t:match("^:") ~= nil
end

---@param line string
---@return boolean
local function is_ternary_branch_ending_line(line)
  local t = strip_trailing_line_comment(line)
  return (t:match("^%?") ~= nil or t:match("^:") ~= nil) and t:match(";%s*$") ~= nil
end

---@param line string
---@return boolean
local function starts_with_method_chain(line)
  local t = strip_trailing_line_comment(line)
  return t:match("^%->") ~= nil
end

---@param bufnr integer
---@param from_lnum integer
---@return integer|nil
local function indent_of_call_open(bufnr, from_lnum)
  for lnum = from_lnum - 1, 1, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local t = vim.trim(l)
    if t:match("%(%s*$") then
      return vim.fn.indent(lnum)
    end
  end
  return nil
end

---@param bufnr integer
---@param from_lnum integer
---@return integer|nil
local function indent_of_method_chain_open(bufnr, from_lnum)
  for lnum = from_lnum - 1, 1, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local t = strip_trailing_line_comment(l)
    if vim.trim(t) ~= "" and not t:match("^%s*%->") then
      return vim.fn.indent(lnum) + vim.fn.shiftwidth()
    end
  end
  return nil
end

---@param bufnr integer
---@param from_lnum integer
---@return integer|nil
local function indent_of_method_chain_base(bufnr, from_lnum)
  for lnum = from_lnum - 1, 1, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local t = strip_trailing_line_comment(l)
    if vim.trim(t) ~= "" and not t:match("^%s*%->") then
      return vim.fn.indent(lnum)
    end
  end
  return nil
end

---@param bufnr integer
---@param from_lnum integer
---@return integer|nil
local function indent_of_ternary_condition(bufnr, from_lnum)
  for lnum = from_lnum - 1, 1, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local t = vim.trim(l)
    if t ~= "" and not t:match("^%?") and not t:match("^:") then
      return vim.fn.indent(lnum) + vim.fn.shiftwidth()
    end
  end
  return nil
end

---@param bufnr integer
---@param from_lnum integer
---@return integer|nil
local function find_open_php_tag_indent(bufnr, from_lnum)
  for lnum = from_lnum, 1, -1 do
    local l = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
    local t = vim.trim(l)
    if t:find("%?>") then
      return nil
    end
    if t:match("^<%?php") and not t:find("%?>") then
      return vim.fn.indent(lnum)
    end
  end
  return nil
end

---@param lnum integer 1-indexed line number (same as |v:lnum| for |indentexpr|).
---@return integer
local function compute(lnum)
  local buf = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""

  -- Treesitter indentation already handles most PSR-12 rules; in mixed HTML/PHP
  -- buffers we only "repair" cases where the next line should be nested
  -- under an opening delimiter (`[` / `{` / `(`), but it isn't.
  local base = ok_ts and ts_indent.get_indent(lnum) or vim.fn.cindent(lnum)

  local is_php_block = find_open_php_tag_indent(buf, lnum) ~= nil
  local is_php_file = buf_filetype(buf) == "php"
  local in_php_context = is_php_block or is_php_file

  if not line:find("^%s*$") then
    -- Closing `);` should align with the call line that opened `(`.
    if in_php_context and is_closing_call_paren_line(line) then
      local target = indent_of_call_open(buf, lnum)
      if target ~= nil then
        return target
      end
    end

    -- Closing `) {` in multiline conditions should align with `if (` / `while (` / etc.
    if in_php_context and is_closing_block_paren_line(line) then
      local target = indent_of_call_open(buf, lnum)
      if target ~= nil then
        return target
      end
    end

    -- Closing `];` should align with `$var = [` (spec Case 4).
    if in_php_context and is_closing_array_bracket_line(line) then
      -- `]);` should align with the call / statement that opened `([`.
      if is_closing_call_array_bracket_line(line) then
        local call_target = indent_of_call_array_open(buf, lnum)
        if call_target ~= nil then
          return call_target
        end
      end

      local target = indent_of_array_assignment_open(buf, lnum)
      -- During `gg=G`, Treesitter can incorrectly indent `];` under the last element.
      -- If we can find the array assignment opener, always align with it.
      if target ~= nil then
        return target
      end
    end

    -- Standalone `]` / `],` / `];` should dedent to the matching opener indent.
    -- `];` is handled above for array assignments; for nested `],` / `]` we align with the nearest `=> [` opener.
    if in_php_context and is_standalone_closing_bracket_line(line) and not is_closing_array_bracket_line(line) then
      local target = indent_of_array_open(buf, lnum) or indent_of_array_item_open(buf, lnum)
      -- Same rationale as `];`: if we can find a matching `=> [` opener,
      -- always align the closing `]`/`],` with it (helps `gg=G`).
      if target ~= nil then
        return target
      end
    end

    local prevlnum = vim.fn.prevnonblank(lnum - 1)
    if prevlnum >= 1 then
      local prev = vim.api.nvim_buf_get_lines(buf, prevlnum - 1, prevlnum, false)[1] or ""

      -- If the previous PHP line opens a block/array/parameter list, indent the
      -- current line one more level (even in mixed `<?php ... ?>` injections).
      if in_php_context then
        -- After the final ternary branch (`: ...;`), the next statement should
        -- align with the assignment/condition line, not stay under ternary branch indent.
        if is_ternary_branch_ending_line(prev) then
          local ternary_indent = indent_of_ternary_condition(buf, lnum)
          local target = ternary_indent ~= nil and (ternary_indent - vim.fn.shiftwidth()) or 0
          if base < 0 then
            return target
          end
          if base ~= target then
            return target
          end
        end

        -- In multiline conditions, keep operator-led continuation lines aligned:
        -- if (
        --   cond
        --   || cond
        --   || cond
        -- ) {
        if starts_with_logical_operator(line) then
          local open_indent = indent_of_call_open(buf, lnum)
          local target = open_indent ~= nil and (open_indent + vim.fn.shiftwidth()) or vim.fn.indent(prevlnum)
          if base < 0 then
            return target
          end
          if base ~= target then
            return target
          end
        end

        -- In multiline ternaries, align `?` and `:` under the condition line.
        if starts_with_ternary_operator(line) then
          local target = indent_of_ternary_condition(buf, lnum) or vim.fn.indent(prevlnum)
          if base < 0 then
            return target
          end
          if base ~= target then
            return target
          end
        end

        -- Multiline fluent chains should keep `->...` lines aligned.
        if starts_with_method_chain(line) then
          local target = indent_of_method_chain_open(buf, lnum) or vim.fn.indent(prevlnum)
          if base < 0 then
            return target
          end
          if base ~= target then
            return target
          end
        end

        -- If the previous line is a dedent-only line (`}`, `];`, `]);`, `],`),
        -- the next statement should align with it (not be nested under it).
        if looks_like_dedent_line(prev) then
          local target = vim.fn.indent(prevlnum)
          if base < 0 then
            return target
          end
          if base > target then
            return target
          end
        end

        local target
        if opens_indented_block(prev) then
          -- For multiline `if (` ... `) {`, the body should be based on the
          -- condition opener indent, not on possibly over-indented `) {`.
          if is_closing_block_paren_line(prev) then
            local open_indent = indent_of_call_open(buf, prevlnum)
            if open_indent ~= nil then
              target = open_indent + vim.fn.shiftwidth()
            else
              target = vim.fn.indent(prevlnum) + vim.fn.shiftwidth()
            end
          else
            target = vim.fn.indent(prevlnum) + vim.fn.shiftwidth()
          end
          if base < 0 then
            return target
          end
          if base ~= target then
            return target
          end
        elseif continues_list_item(prev) then
          target = vim.fn.indent(prevlnum)
          if base >= 0 and base < target then
            return target
          end
        elseif continues_after_statement(prev) and not looks_like_dedent_line(line) then
          target = vim.fn.indent(prevlnum)
          -- After a fluent chain terminator (`->...;`), the next statement
          -- should align with the chain base (e.g. variable assignment),
          -- not remain at chained-method indentation.
          if starts_with_method_chain(prev) then
            target = indent_of_method_chain_base(buf, lnum) or target
            if base < 0 then
              return target
            end
            if base ~= target then
              return target
            end
          end
          if base >= 0 and base < target then
            return target
          end
        end

        -- Directly after an opening `<?php` tag, don't add extra indentation.
        if continues_after_open_php_tag(prev) then
          return math.max(base, vim.fn.indent(prevlnum))
        end
      end

      if is_static_call_continuation(prev) then
        local hang = vim.fn.indent(prevlnum) + vim.fn.shiftwidth()
        if base < 0 then
          return hang
        end
        return math.max(base, hang)
      end
    end

    return base
  end

  local prevlnum = vim.fn.prevnonblank(lnum - 1)
  if prevlnum < 1 then
    return base
  end

  local prev = vim.api.nvim_buf_get_lines(buf, prevlnum - 1, prevlnum, false)[1] or ""

  -- Blank line right after an opening delimiter should indent one more level.
  -- This is the common "hit Enter after `=> [`" / `(` / `{` case (spec Case 5).
  if in_php_context and opens_indented_block(prev) then
    local target = vim.fn.indent(prevlnum) + vim.fn.shiftwidth()
    if base < 0 then
      return target
    end
    return math.max(base, target)
  end

  if continues_after_open_php_tag(prev) then
    local same = vim.fn.indent(prevlnum)
    if base < 0 then
      return same
    end
    return math.max(base, same)
  end

  -- Blank new line after `,` / `;` with trailing `//` comment (spec Case 4).
  if in_php_context then
    if continues_list_item(prev) or (continues_after_statement(prev) and not looks_like_dedent_line(line)) then
      local target = vim.fn.indent(prevlnum)
      if base < 0 then
        return target
      end
      return math.max(base, target)
    end
  end

  -- For blank lines, keep the existing treesitter behavior except for the
  -- explicit mixed `<?php` handling above.
  return base
end

---@return integer
function indentexpr()
  return compute(vim.v.lnum)
end

return {
  indentexpr = indentexpr,
  compute = compute,
}
