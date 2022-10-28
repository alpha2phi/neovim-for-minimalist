local test_function_query_string = [[
;; query
(
 class_definition
  name: (identifier) @test_class_name
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

local PATH_SEP = package.config:sub(1, 1)

local escape_pattern = function(text)
	return text:gsub("([^%w])", "%%%1")
end

local print_output = function(unit_test)
	local output = table.concat(unit_test.test_output, "\n")
	print(output)
end

local add_test_result = function(unit_test, test_name, test_status)
	unit_test.test_cases[test_name]["status"] = test_status
end

local add_test_output = function(unit_test, line)
	table.insert(unit_test.test_output, line)
end

local find_test_cases = function(bufnr, unit_test)
	local query = vim.treesitter.parse_query("python", test_function_query_string)
	local parser = vim.treesitter.get_parser(bufnr, "python", {})
	local tree = parser:parse()[1]
	local root = tree:root()

	local count = 0
	local curr_row = vim.api.nvim_win_get_cursor(0)[1]
	local prev_test_case = ""

	for id, node in query:iter_captures(root, bufnr, 0, -1) do
		local name = query.captures[id]
		if name == "func_name" then
			local range = { node:range() }
			local test_case_name = vim.treesitter.get_node_text(node, bufnr)
			count = count + 1
			unit_test.test_cases[test_case_name] = { name = test_case_name, range = range, status = "" }

			if unit_test.nearest_test_case == "" then
				if (range[1] + 1) > curr_row then
					if prev_test_case ~= "" then
						unit_test.nearest_test_case = prev_test_case
					else
						unit_test.nearest_test_case = test_case_name
					end
				end
				prev_test_case = test_case_name
			end
		elseif name == "test_class_name" then
			local test_class_name = vim.treesitter.get_node_text(node, bufnr)
			unit_test["class_name"] = test_class_name
		end
		unit_test["count"] = count
	end
	if unit_test.nearest_test_case == "" then
		unit_test.nearest_test_case = prev_test_case
	end
end

local ns = vim.api.nvim_create_namespace("ns-alpha-python-test")
local last_test_cmd = {}
local last_file_name = ""

local run_test = function(bufnr, opt)
	local unit_test = {
		bufnr = bufnr,
		file_name = "",
		class_name = "",
		count = 0,
		test_cases = {},
		test_output = {},
		nearest_test_case = "",
	}

	-- Find test cases in the current buffer
	find_test_cases(bufnr, unit_test)
	if unit_test.count == 0 then
		vim.notify("No test case found", vim.log.levels.ERROR)
		return
	end

	unit_test.file_name = vim.api.nvim_buf_get_name(bufnr)
	local cmd = { "python", "-m", "unittest", "-v" }
	local test_file = vim.api.nvim_buf_get_name(bufnr):gsub(escape_pattern(vim.fn.getcwd()), ""):gsub(".py", "")
	local modules = vim.fn.split(test_file, PATH_SEP, false)
	if opt == "nearest" then
		table.insert(
			cmd,
			vim.fn.join(modules, ".") .. "." .. unit_test["class_name"] .. "." .. unit_test["nearest_test_case"]
		)
	elseif opt == "last" then
		if #last_test_cmd == 0 then
			vim.notify("No last test found", vim.log.levels.INFO)
			return
		end
		cmd = last_test_cmd
	else
		table.insert(cmd, vim.fn.join(modules, ".") .. "." .. unit_test["class_name"])
	end

	last_test_cmd = cmd
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	vim.fn.jobstart(cmd, {
		stderr_buffered = true,
		on_stderr = function(_, data)
			if not data then
				return
			end
			for _, line in ipairs(data) do
				-- All output
				add_test_output(unit_test, line)

				-- Test case result
				if string.match(line, [[%.%.%.]]) then
					local result = vim.fn.split(line, " ", true)
					local test_name = result[1]
					local test_status = result[#result]

					add_test_result(unit_test, test_name, test_status)
					if test_status == "ok" then
						local text = { "" }
						vim.api.nvim_buf_set_extmark(bufnr, ns, unit_test.test_cases[test_name]["range"][1], 0, {
							virt_text = { text },
						})
					end
				end
			end
		end,
		on_exit = function()
			local failed = {}
			for _, test in pairs(unit_test.test_cases) do
				if test["status"] == "FAIL" then
					table.insert(failed, {
						bufnr = bufnr,
						lnum = test["range"][1],
						col = 0,
						severity = vim.diagnostic.severity.ERROR,
						source = "python-test",
						message = "Test Failed",
						user_data = {},
					})
				end
			end
			vim.diagnostic.set(ns, bufnr, failed, {})
		end,
	})
end

-- Test all
vim.api.nvim_create_user_command("PyTestAll", function()
	run_test(vim.api.nvim_get_current_buf(), "all")
end, {})

-- Test nearest
vim.api.nvim_create_user_command("PyTestNearest", function()
	run_test(vim.api.nvim_get_current_buf(), "nearest")
end, {})

-- Test last
vim.api.nvim_create_user_command("PyTestLast", function()
	run_test(vim.api.nvim_get_current_buf(), "last")
end, {})

run_test(100, " last")
