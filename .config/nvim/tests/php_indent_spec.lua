---Column of first non-blank character (like |indent()| with tabstop=4).
local function indent_column(line, tabstop)
  tabstop = tabstop or 4
  local col = 0
  for i = 1, #line do
    local c = line:sub(i, i)
    if c == " " then
      col = col + 1
    elseif c == "\t" then
      col = col + tabstop - (col % tabstop)
    else
      break
    end
  end
  return col
end

local function trim(s)
  s = s or ""
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error((msg or "assert_eq failed") .. (" expected=%s got=%s"):format(tostring(expected), tostring(actual)), 2)
  end
end

-- Resolve repo root (so `require("php_indent")` works).
local script_path = debug.getinfo(1, "S").source:sub(2)
local repo_root = script_path:match("(.+)/tests/") or "."
local lua_dir = repo_root .. "/lua"
package.path = lua_dir .. "/?.lua;" .. package.path

-- Force reload so our stubs are used even if Neovim already loaded modules.
package.loaded["php_indent"] = nil
package.loaded["nvim-treesitter.indent"] = nil

-- Stubs used by php_indent.lua
local buffer_lines = {}
local base_indents = {}
local shiftwidth = 4

package.loaded["nvim-treesitter.indent"] = {
  get_indent = function(lnum)
    -- `php_indent.compute()` expects an integer base indent. Use -1 to mean "unknown".
    return base_indents[lnum] or -1
  end,
}

-- Minimal `vim` surface needed by `lua/php_indent.lua`.
local v = _G.vim or {}
_G.vim = v
-- Force a deterministic surface even when run inside Neovim.
v.trim = trim

v.api = v.api or {}
v.api.nvim_get_current_buf = function()
  return 1
end

v.api.nvim_buf_get_lines = function(_, start, end_, _)
  -- Neovim API is 0-indexed, end is exclusive.
  local res = {}
  for i = start + 1, end_ do
    res[#res + 1] = buffer_lines[i] or ""
  end
  return res
end

v.fn = v.fn or {}
v.fn.shiftwidth = function()
  return shiftwidth
end

v.bo.filetype = "php"

v.fn.indent = function(lnum)
  return indent_column(buffer_lines[lnum] or "", shiftwidth)
end

v.fn.prevnonblank = function(lnum)
  for i = lnum, 1, -1 do
    local line = buffer_lines[i] or ""
    if not line:match("^%s*$") then
      return i
    end
  end
  return 0
end

-- Load code under test.
local php_indent = require("php_indent")

local function run_case(name, lines, base_for_lnum, lnum, expected)
  buffer_lines = lines
  base_indents = base_for_lnum or {}

  local actual = php_indent.compute(lnum)
  assert_eq(actual, expected, name)
end

---Assert |indentexpr| column for multiple lines (treesitter base defaults to -1).
local function run_buffer_case(name, lines, base_for_lnum, expected_by_lnum)
  buffer_lines = lines
  base_indents = base_for_lnum or {}
  for lnum, expected in pairs(expected_by_lnum) do
    local actual = php_indent.compute(lnum)
    assert_eq(actual, expected, name .. (" @ line %d"):format(lnum))
  end
end

-- Spec.md behavior coverage:
-- 1) Static call hanging indent when previous line has no trailing `;`
--    (spec: Query::where() + cursor enter)
run_case(
  "static-call continuation",
  {
    "<?php",
    "Query::where()",
    "$x = 1;",
  },
  {
    [3] = 0, -- base indent from treesitter
  },
  3,
  4 -- indent(prev) + shiftwidth
)

-- 2) List item continuation on comma-ending previous line
--    (spec: $array = [ ... 'key' => 'value', <enter> ... ])
run_case(
  "list-item continuation",
  {
    "<?php",
    "$array = [",
    "    'key' => 'value',",
    "    // next line",
  },
  {
    [4] = 0, -- base indent from treesitter
  },
  4,
  4 -- indent(prev)
)

-- 3) Mixed HTML/PHP: if previous PHP line opens a block (`{`),
--    indent the current line one level more.
--    (spec: nested indentation continues under opening delimiter)
run_case(
  "mixed-html/php open-block indentation",
  {
    "<div>",
    "<?php",
    "if ($x) {",
    "$y = 1;",
  },
  {
    [4] = 0, -- base indent from treesitter
  },
  4,
  4
)

-- 4) Mixed HTML/PHP: directly after opening `<?php` on a multiline tag,
--    don't add extra indentation; align with the `<?php` tag level.
--    (spec: multiline php after opening tag treated as html tag with same indentation)
run_case(
  "mixed-html/php after opening tag",
  {
    "<div>",
    "<?php //multiline php code should be treated as html",
    "$array = [];",
  },
  {
    [3] = -1, -- force repair path (base < indent(prev))
  },
  3,
  0
)

-- Case 4 (spec.md): after a line ending with `,` or `;` but with a trailing `//`
-- comment, the next line should keep the same indent as that statement (not
-- dedent to column 0). Closing `];` should align with `$var = [`.
run_case(
  "case 4: enter after array element with comma and trailing // comment",
  {
    '<div class="line big mx-auto"></div>',
    "<?php",
    "$cats = [",
    "    'taxonomy' => 'category',",
    "    'field'    => 'term_id',",
    "    'terms'    => [], // when I'm here and click enter",
    "    // next line",
  },
  {
    [7] = 0, -- treesitter returns 0; we should align with previous array lines
  },
  7,
  4
)

run_case(
  "case 4: enter after foreach body statement with ; and trailing // comment",
  {
    '<div class="line big mx-auto"></div>',
    "<?php",
    "foreach ($categories as $category) {",
    "    $cats['terms'][] = $category->term_id; // when I'm here and click enter",
    "    // next line",
  },
  {
    [5] = 0,
  },
  5,
  4
)

run_case(
  "case 4: closing ]; aligns with opening $var = [",
  {
    '<div class="line big mx-auto"></div>',
    "<?php",
    "$cats = [",
    "    'taxonomy' => 'category',",
    "    ];",
  },
  {
    [5] = 4, -- wrong: over-indented relative to $cats
  },
  5,
  0
)

-- Case 4 (realistic tabs): `];` must align with `$cats = [`; `foreach` / `$more_posts_params` / `$news`
-- must not be indented under `];`. Previously `];` matched `continues_after_statement` because it ends
-- with `;`, which boosted the next line to match the wrong `];` indent.
run_buffer_case(
  "case 4: full snippet — ]; foreach } second ]; $news (tabs)",
  {
    "<?php",
    "$cats = [",
    "\t'taxonomy' => 'category',",
    "\t'field'    => 'term_id',",
    "\t'terms'    => [],",
    "];",
    "foreach ($categories as $category) {",
    "\t$cats['terms'][] = $category->term_id;",
    "}",
    "$more_posts_params = [",
    "\t'post_type'        => 'post',",
    "\t'posts_per_page'   => 3,",
    "\t'exclude'          => get_the_ID(),",
    "\t'tax_query'        => [ $cats ],",
    "\t'suppress_filters' => false,",
    "];",
    "$news = get_posts( $more_posts_params );",
  },
  (function()
    local b = {}
    for i = 1, 17 do
      b[i] = 0
    end
    b[6] = 4 -- treesitter over-indents first `];` relative to `$cats`
    b[16] = 4 -- treesitter over-indents second `];` relative to `$more_posts_params`
    return b
  end)(),
  {
    [6] = 0, -- `];` with `$cats`
    [7] = 0, -- foreach (not nested under `];`)
    [8] = 4, -- foreach body
    [9] = 0, -- `}`
    [10] = 0, -- `$more_posts_params`
    [11] = 4,
    [12] = 4,
    [13] = 4,
    [14] = 4,
    [15] = 4,
    [16] = 0, -- closing `];`
    [17] = 0, -- `$news`
  }
)

-- Case 5 (spec.md): nested array item open/close.
-- After `'nested_array' => [` the next line should indent one more level.
-- The closing `],` must align with the `'nested_array'` line, not with inner items.
-- The outer `];` must align with `$more_posts_params = [`.
run_buffer_case(
  "case 5: nested array item indentation + closing ], alignment",
  {
    "<?php",
    "$more_posts_params = [",
    "\t'post_type'        => 'post',",
    "\t'posts_per_page'   => 3,",
    "\t'exclude'          => get_the_ID(),",
    "\t'tax_query'        => [ $cats ],",
    "\t'suppress_filters' => false,",
    "\t'nested_array' => [",
    "\t\t'wat' => 'lol',",
    "\t],",
    "];",
    "$news = get_posts( $more_posts_params );",
  },
  (function()
    local b = {}
    for i = 1, 12 do
      b[i] = 0
    end
    -- Simulate the common treesitter failure modes:
    -- - over-indent nested closing `],`
    -- - over-indent outer closing `];`
    b[10] = 8
    b[11] = 4
    return b
  end)(),
  {
    [9] = 8, -- inner item under nested array
    [10] = 4, -- `],` aligns with `\t'nested_array' => [`
    [11] = 0, -- outer `];` aligns with `$more_posts_params = [`
    [12] = 0, -- next statement not nested under `];`
  }
)

run_buffer_case(
  "case 5c: closing ], and ]; with trailing // comments dedent",
  {
    "$more_posts_params = [",
    "\t'nested_array' => [",
    "\t\t'wat' => 'lol',",
    "\t], //incorrect",
    "\t]; // incorrect indentation, this bracket should be on the same level with $more_posts_params",
    "$news = get_posts( $more_posts_params );",
  },
  {
    [4] = 8,
    [5] = 4,
    [6] = 0,
  },
  {
    [4] = 4, -- `], //...` aligns with `\t'nested_array' => [`
    [5] = 0, -- `]; //...` aligns with `$more_posts_params = [`
    [6] = 0, -- next statement
  }
)

run_buffer_case(
  "case 5b: closing ] / ], dedents even in pure php file",
  {
    "$x = [",
    "\t'nested' => [",
    "\t\t'k' => 'v',",
    "\t],",
    "];",
  },
  {
    [4] = 8, -- treesitter over-indents `],`
    [5] = 4, -- treesitter over-indents outer `];`
  },
  {
    [4] = 4, -- `],` aligns with `\t'nested' => [`
    [5] = 0, -- `];` aligns with `$x = [`
  }
)

run_buffer_case(
  "nested: closing ] aligns with key => [ (even if treesitter returns 0)",
  {
    "$cats = [",
    "\t'' => [",
    "\t\t'',",
    "\t] //this should be on level with '' key",
    "];",
  },
  {
    [4] = 0, -- treesitter can incorrectly dedent during reindent
    [5] = 0,
  },
  {
    [4] = 4, -- `]` aligns with `\t'' => [`
    [5] = 0, -- `];` aligns with `$cats = [`
  }
)

-- PHP-only file: `]);` should dedent like `];` (common in function/method calls).
-- The next statement must not be indented under `]);`.
run_buffer_case(
  "php-only: method call array close `]);` + following return view array `]);`",
  {
    "<?php",
    "$payment->update([",
    "    'request_payload' => [",
    "        'merchant_parameters' => $merchantParams,",
    "        'signature_version' => $payload['Ds_SignatureVersion'],",
    "    ],",
    "]);",
    "return view('payments.redsys-redirect', [",
    "    'gatewayUrl' => $redsys->getGatewayUrl(),",
    "    'payload' => $payload,",
    "]);",
  },
  {
    -- Simulate Treesitter over-indenting closing `]);` and the next statement during `gg=G`.
    [7] = 4,
    [8] = 4,
    [11] = 4,
  },
  {
    [7] = 0, -- `]);` aligns with `$payment->update([`
    [8] = 0, -- next statement not nested under `]);`
    [11] = 0, -- `]);` aligns with `return view(..., [`
  }
)

run_buffer_case(
  "php-only: multiline call arg array `],` + closing `);` align with openers",
  {
    "<?php",
    "$euCredential = UpsCredential::query()->updateOrCreate(",
    "    ['name' => 'UPS EU'],",
    "    [",
    "        'is_active' => true,",
    "        'environment' => 'sandbox',",
    "        'client_id' => $clientId !== '' ? $clientId : null,",
    "        'client_secret' => $clientSecret !== '' ? $clientSecret : null,",
    "        ],",
    "        );",
  },
  {
    -- Simulate Treesitter over-indenting both closing lines.
    [9] = 8,
    [10] = 8,
  },
  {
    [9] = 4, -- `],` aligns with line containing the second arg `[`
    [10] = 0, -- `);` aligns with `updateOrCreate(`
  }
)

run_buffer_case(
  "php-only: multiline if conditions closing `) {` aligns with `if (`",
  {
    "<?php",
    "if (",
    "    ! Schema::hasTable('ups_credentials')",
    "        || ! Schema::hasTable('shipping_countries')",
    "            || ! Schema::hasTable('shipping_countries_ups_credentials')",
    "                ) {",
    "                    return;",
    "}",
  },
  {
    -- Simulate Treesitter drifting the closing `) {` and the body.
    [6] = 16,
    [7] = 20,
    [8] = 0,
  },
  {
    [6] = 0, -- `) {` aligns with `if (`
    [7] = 4, -- body is one shiftwidth under `if (`
    [8] = 0, -- closing brace aligns with `if (`
  }
)

run_buffer_case(
  "php-only: multiline logical operator lines do not staircase",
  {
    "<?php",
    "if (",
    "    ! Schema::hasTable('ups_credentials')",
    "        || ! Schema::hasTable('shipping_countries')",
    "            || ! Schema::hasTable('shipping_countries_ups_credentials')",
    ") {",
    "    return;",
    "}",
  },
  {
    -- Simulate Treesitter drifting continuation lines to the right.
    [4] = 8,
    [5] = 12,
    [8] = 0,
  },
  {
    [3] = 4,
    [4] = 4, -- `||` line aligns with first condition line
    [5] = 4, -- next `||` line keeps same alignment
    [6] = 0, -- closing `)` aligns with `if (`
    [7] = 4,
    [8] = 0,
  }
)

run_buffer_case(
  "php-only: multiline ternary `?` and `:` align under condition line",
  {
    "<?php",
    "$targetCredentialId = in_array($iso2, self::EU_COUNTRY_ISO2, true)",
    "? (int) $euCredential->getKey()",
    ": (int) $rowCredential->getKey();",
  },
  {
    -- Simulate Treesitter under-indenting ternary operator lines.
    [3] = 0,
    [4] = 0,
  },
  {
    [3] = 4,
    [4] = 4,
  }
)

run_buffer_case(
  "php-only: statement after multiline ternary dedents",
  {
    "<?php",
    "$targetCredentialId = in_array($iso2, self::EU_COUNTRY_ISO2, true)",
    "    ? (int) $euCredential->getKey()",
    "    : (int) $rowCredential->getKey();",
    "    DB::table('shipping_countries_ups_credentials')->updateOrInsert(",
  },
  {
    -- Simulate Treesitter carrying ternary indent onto next statement.
    [5] = 4,
  },
  {
    [5] = 0, -- should align with `$targetCredentialId = ...`
  }
)

run_buffer_case(
  "php-only: multiline chained method calls keep `->` indentation level",
  {
    "<?php",
    "DB::table('shipping_countries_ups_credentials')",
    "    ->where('shipping_country_id', (int) $shippingCountry->getKey())",
    "->whereIn('ups_credential_id', [(int) $euCredential->getKey(), (int) $rowCredential->getKey()])",
    "->where('ups_credential_id', '!=', $targetCredentialId)",
    "->delete();",
  },
  {
    -- Simulate Treesitter dropping chain indentation after first method.
    [4] = 0,
    [5] = 0,
    [6] = 0,
  },
  {
    [3] = 4,
    [4] = 4,
    [5] = 4,
    [6] = 4,
  }
)

run_buffer_case(
  "php-only: line after chained method terminator dedents to chain base",
  {
    "<?php",
    "$shippingCountries = ShippingCountry::query()",
    "    ->with('country:id,iso2')",
    "    ->get();",
    "    foreach ($shippingCountries as $shippingCountry) {",
  },
  {
    -- Simulate Treesitter keeping chain indent on the next statement.
    [5] = 4,
  },
  {
    [3] = 4,
    [4] = 4,
    [5] = 0, -- `foreach` aligns with `$shippingCountries = ...`
  }
)

print("php_indent_spec.lua: OK")

