local add_test_result = function(results, test_name, test_status)
  results.test_result[test_name] = test_status
end

local add_test_output = function(results, line)
  table.insert(results.test_output, line)
end

local ns = vim.api.nvim_create_namespace("ns-alpha-python-test")
local group = vim.api.nvim_create_augroup("au-alpha-python-test", { clear = true })
local automated_test = function(bufnr, cmd)
  local results = {
    bufnr = bufnr,
    test_result = {},
    test_output = {},
  }
  vim.fn.jobstart(cmd, {
    stderr_buffered = true,
    on_stderr = function(_, data)
      if not data then
        return
      end
      for _, line in ipairs(data) do
        -- All output
        add_test_output(results, line)

        -- Test case result
        if string.match(line, [[%.%.%.]]) then
          local result = vim.fn.split(line, " ", true)
          add_test_result(results, result[1], result[#result])
        end
      end
    end,
    on_exit = function()
      -- local output = table.concat(results.test_output, "\n")
      -- print(output)
      vim.pretty_print(results)
    end,
  })
end

automated_test(
  vim.api.nvim_get_current_buf(),
  { "python", "-m", "unittest", "-v", "tests.test_cases.TestStringMethods" }
)

-- vim.api.nvim_create_user_command("AutoTestFile", function()
--   print("tdd")
-- end, {})

-- test_split (tests.test_cases.TestStringMethods) ... ok
-- test_upper (tests.test_cases.TestStringMethods) ... ok

-- python -m unittest -v tests.test_cases.TestStringMethods.test_isupper
