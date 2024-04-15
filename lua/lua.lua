local lua = {}
local utils = require'utils'
local TYPES = utils.TYPES

lua.context = function(opts, bufnr)
	local ns_id = vim.api.nvim_create_namespace('closing-context')
	local root = vim.treesitter.get_parser(bufnr, 'lua'):parse()[1]:root()

	local function get_text(node)
		return vim.treesitter.get_node_text(node, bufnr)
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	-- add variable declaration keyword and name to end of block if not all on one line
	local query = vim.treesitter.query.parse('lua', [[
		(assignment_statement
			(variable_list) @variable_name
		) @assignment_statement
	]])

	for _, variable_delcaration_node in query:iter_matches(root, bufnr, 0, -1) do
		local variable_name = get_text(variable_delcaration_node[1])
		utils.write_vtext(TYPES.VARIABLE, opts, bufnr, ns_id, variable_delcaration_node[2], "var", variable_name)
	end

	-- function declaration
	query = vim.treesitter.query.parse('lua', [[
		(function_definition
			parameters: (parameters) @parameters
		) @function_definition
	]])

	for _, function_declaration_node in query:iter_matches(root, bufnr, 0, -1) do
		local parameters = get_text(function_declaration_node[1])
		utils.write_vtext(TYPES.FUNCTION, opts, bufnr, ns_id, function_declaration_node[2], 'function', parameters)
	end


	-- if statement
	query = vim.treesitter.query.parse('lua', [[
		(if_statement
			condition: (_) @condition
		) @if_statement
	]])

	for _, if_node in query:iter_matches(root, bufnr, 0, -1) do
		local else_info = ""
		local child_node = if_node[1]:next_named_sibling()
		-- find the else clauses and get their information
		while child_node ~= nil do
			local child_type = child_node:type()
			if child_type == "elseif_statement" then
				local else_condition = child_node:child(1)
					else_info = else_info .. ", elseif " .. get_text(else_condition)
			elseif child_type == "else_statement" then
				else_info = else_info .. ", else"
			end
			child_node = child_node:next_named_sibling()
		end
		local if_condition = get_text(if_node[1]) .. else_info
		utils.write_vtext(TYPES.IF, opts, bufnr, ns_id, if_node[2], 'if', if_condition)
	end

	-- while statement
	query = vim.treesitter.query.parse('lua', [[
		(while_statement
			condition: (_) @condition
		) @while_statement
	]])

	for _, while_node in query:iter_matches(root, bufnr, 0, -1) do
		local while_condition = get_text(while_node[1])
		utils.write_vtext(TYPES.IF, opts, bufnr, ns_id, while_node[2], 'while', while_condition)
	end

	-- for statement
	query = vim.treesitter.query.parse('lua', [[
		(for_statement
			clause: (_
				(expression_list) @condition
		) @for_statement
	]])

	for _, for_node in query:iter_matches(root, bufnr, 0, -1) do
		local for_condition = get_text(for_node[1])
		utils.write_vtext(TYPES.IF, opts, bufnr, ns_id, for_node[2], 'for', for_condition)
	end
end

return lua
