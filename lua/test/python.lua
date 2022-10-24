local test_function_query_string = [[
;; query
(
 class_definition
  superclasses:  (argument_list
    (attribute) @test_class
   )
  body: (block
    (function_definition
      name: (identifier) @func_name
    )
  )
 )
]]
