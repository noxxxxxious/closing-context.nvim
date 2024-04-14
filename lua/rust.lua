local rust = {}
local utils = require'utils'
local TYPES = utils.TYPES

rust.context = function(opts, bufnr)
	local ns_id = vim.api.nvim_create_namespace('closing-context')
	local root = vim.treesitter.get_parser(bufnr, 'rust'):parse()[1]:root()

	local function get_text(node)
		return vim.treesitter.get_node_text(node, bufnr)
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	-- add name of function to end of function declaration blocks
	local query = vim.treesitter.query.parse('rust', [[
		(function_item
			name: (identifier) @function_name
		) @function_node
	]])

	for _, fn_node in query:iter_matches(root, bufnr, 0, -1) do
		local fn_name = get_text(fn_node[1])
		utils.write_vtext(TYPES.FUNCTION, opts, bufnr, ns_id, fn_node[2], 'fn', fn_name)
	end

	-- add while <condition> to end of while block
	query = vim.treesitter.query.parse('rust', [[
		(while_expression
			condition: (_) @condition
		) @while_expression
	]])

	for _, while_node in query:iter_matches(root, bufnr, 0, -1) do
		local condition = get_text(while_node[1])
		utils.write_vtext(TYPES.WHILE, opts, bufnr, ns_id, while_node[2], 'while', condition)
	end

	-- compile if statements and display on last line
	query = vim.treesitter.query.parse('rust', [[
		(if_expression
			condition: (_) @condition
		) @if_expression
	]])

	for _, if_node in query:iter_matches(root, bufnr, 0, -1) do
		-- make sure it's a standalone block and not used for variable declaration
		if if_node[2]:parent():type() ~= "let_declaration" then
			local condition = get_text(if_node[1])
			utils.write_vtext(TYPES.IF, opts, bufnr, ns_id, if_node[2], 'if', condition)
		end
	end

	-- add match <condition> to end of match block
	query = vim.treesitter.query.parse('rust', [[
		(match_expression
			value: (_) @value
		) @match_expression
	]])

	for _, match_node in query:iter_matches(root, bufnr, 0, -1) do
		-- make sure it's a standalone block and not used for variable declaration
		if match_node[2]:parent():type() ~= "let_declaration" then
			local condition = get_text(match_node[1])
			utils.write_vtext(TYPES.MATCH, opts, bufnr, ns_id, match_node[2], 'match', condition)
		end
	end

	-- add let <identifier> to end of let declaration that uses
	query = vim.treesitter.query.parse('rust', [[
		(let_declaration
			pattern: (_) @pattern
		) @let_declaration
	]])
	
	for _, let_node in query:iter_matches(root, bufnr, 0, -1) do
		local pattern = get_text(let_node[1])
		utils.write_vtext(TYPES.VARIABLE, opts, bufnr, ns_id, let_node[2], 'let', pattern)
	end
end

return rust
