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

local find_test_cases = function(bufnr)
  local query = vim.treesitter.parse_query("python", test_function_query_string)
  local parser = vim.treesitter.get_parser(bufnr, "python", {})
  local tree = parser:parse()[1]
  local root = tree:root()

  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    if id == 1 then
      local range = { node:range() }
      return range[1]
    end
  end
end
