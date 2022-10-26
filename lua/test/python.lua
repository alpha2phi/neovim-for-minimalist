local test_function_query_string = [[
;; query
(
 class_definition
  superclasses:  (argument_list
    (attribute) @test_class (#eq? @test_class "unittest.TestCase")
   )
  body: (block
    (function_definition
      name: (identifier) @func_name (#match? @func_name "^test_")
    )
  )
 )

]]

local print_output = function(test_cases)
  local output = table.concat(test_cases.test_output, "\n")
  print(output)
end

local add_test_result = function(test_cases, test_name, test_status)
  test_cases.test_result[test_name]["status"] = test_status
end

local add_test_output = function(test_cases, line)
  table.insert(test_cases.test_output, line)
end

local find_all_test_cases = function(bufnr, test_cases)
  local query = vim.treesitter.parse_query("python", test_function_query_string)
  local parser = vim.treesitter.get_parser(bufnr, "python", {})
  local tree = parser:parse()[1]
  local root = tree:root()

  local count = 0
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local name = query.captures[id]
    if name == "func_name" then
      local range = { node:range() }
      local test_case_name = vim.treesitter.get_node_text(node, bufnr)
      count = count + 1
      test_cases.test_result[test_case_name] = { range = range, status = "" }
    end
    test_cases["count"] = count
  end
end

local find_nearest_test_case = function(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
end

-- local ns = vim.api.nvim_create_namespace("ns-alpha-python-test")
-- local group = vim.api.nvim_create_augroup("au-alpha-python-test", { clear = true })

local automated_test = function(bufnr, cmd)
  local test_cases = {
    bufnr = bufnr,
    count = 0,
    test_result = {},
    test_output = {},
  }

  find_all_test_cases(bufnr, test_cases)
  if test_cases.count == 0 then
    vim.notify("No test case found", vim.log.levels.ERROR)
    return
  end

  vim.fn.jobstart(cmd, {
    stderr_buffered = true,
    on_stderr = function(_, data)
      if not data then
        return
      end
      for _, line in ipairs(data) do
        -- All output
        add_test_output(test_cases, line)

        -- Test case result
        if string.match(line, [[%.%.%.]]) then
          local result = vim.fn.split(line, " ", true)
          add_test_result(test_cases, result[1], result[#result])
        end
      end
    end,
    on_exit = function()
      vim.pretty_print(test_cases)
    end,
  })
end

local bufnr = 26
-- find_all_test_cases(bufnr)
-- find_nearest_test_case(bufnr)

automated_test(
-- vim.api.nvim_get_current_buf(),
  bufnr,
  { "python", "-m", "unittest", "-v", "tests.test_cases.TestStringMethods" }
)

-- python -m unittest -v tests.test_cases.TestStringMethods.test_isupper
