local javascript = {}
local utils = require'utils'
local TYPES = utils.TYPES

javascript.context = function(opts, bufnr)
	local ns_id = vim.api.nvim_create_namespace('closing-context')
	local root = vim.treesitter.get_parser(bufnr, 'javascript'):parse()[1]:root()

	local function get_text(node)
		return vim.treesitter.get_node_text(node, bufnr)
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	-- add variable declaration keyword and name to end of block if not all on one line
	local query = vim.treesitter.query.parse('javascript', [[
		(lexical_declaration
			(variable_declarator
				name: (identifier) @variable_name
			)
		) @lexical_declaration
	]])

	for _, variable_delcaration_node in query:iter_matches(root, bufnr, 0, -1) do
		local keyword = get_text(variable_delcaration_node[2])
		keyword = utils.split_string(keyword, " ")[1]
		local variable_name = get_text(variable_delcaration_node[1])
		utils.write_vtext(TYPES.VARIABLE, opts, bufnr, ns_id, variable_delcaration_node[2], keyword, variable_name)
	end

	-- function declaration
	query = vim.treesitter.query.parse('javascript', [[
		(function_declaration
			name: (identifier) @variable_name
		) @function_declaration
	]])

	for _, function_declaration_node in query:iter_matches(root, bufnr, 0, -1) do
		local function_name = get_text(function_declaration_node[1])
		utils.write_vtext(TYPES.FUNCTION, opts, bufnr, ns_id, function_declaration_node[2], 'function', function_name)
	end

	-- switch statement
	query = vim.treesitter.query.parse('javascript', [[
		(switch_statement
			value: (_) @expression
		) @switch_statement
	]])

	for _, switch_node in query:iter_matches(root, bufnr, 0, -1) do
		local switch_condition = get_text(switch_node[1])
		utils.write_vtext(TYPES.SWITCH, opts, bufnr, ns_id, switch_node[2], 'switch', switch_condition)
	end

	-- while statement
	query = vim.treesitter.query.parse('javascript', [[
		(while_statement
			condition: (_) @condition
		) @while_statement
	]])

	for _, while_node in query:iter_matches(root, bufnr, 0, -1) do
		local condition = get_text(while_node[1])
		utils.write_vtext(TYPES.WHILE, opts, bufnr, ns_id, while_node[2], 'while', condition)
	end

	-- if statement
	query = vim.treesitter.query.parse('javascript', [[
		(if_statement
			condition: (_) @condition
		) @if_statement
	]])

	-- recursive function to get all else_statement information
	local recurse_else
	recurse_else = function(if_node, else_info)
		local child_node = if_node:child(1)
		else_info = else_info .. ", else if (" .. get_text(child_node:child(1)) .. ")"
		while child_node ~= nil do
			if child_node:type() == "else_clause" then
				local else_child = child_node:child(1)
				if else_child:type() == "if_statement" then
					else_info = recurse_else(else_child, else_info)
				else
					else_info = else_info .. ", else {}"
				end
			end
			child_node = child_node:next_named_sibling()
		end
		return else_info
	end

	for _, if_node in query:iter_matches(root, bufnr, 0, -1) do
		-- make sure it's a standalone block and not an else
		if if_node[2]:parent():type() ~= "else_clause" then
			local else_info = ""
			local child_node = if_node[1]:next_named_sibling()
			-- find the else clauses and get their information
			while child_node ~= nil do
				if child_node:type() == "else_clause" then
					local else_child = child_node:child(1)
					if else_child:type() == "if_statement" then
						else_info = else_info .. recurse_else(else_child, else_info)
					else
						else_info = else_info .. ", else {}"
					end
				end
				child_node = child_node:next_named_sibling()
			end
			local if_condition = get_text(if_node[1]) .. else_info
			utils.write_vtext(TYPES.IF, opts, bufnr, ns_id, if_node[2], 'if', if_condition)
		end
	end

	-- for statement
	query = vim.treesitter.query.parse('javascript', [[
		(for_statement
			initializer: (_) @initializer
			condition: (_) @condition
			increment: (_) @increment
		) @for_statement
	]])

	for _, for_node in query:iter_matches(root, bufnr, 0, -1) do
		local initializer = get_text(for_node[1])
		local condition = get_text(for_node[2])
		local increment = get_text(for_node[3])
		local parenthesis_text = "(" .. initializer .. " " .. condition .. " " .. increment .. ")"
		utils.write_vtext(TYPES.FOR, opts, bufnr, ns_id, for_node[4], 'for', parenthesis_text)
	end
end

return javascript
