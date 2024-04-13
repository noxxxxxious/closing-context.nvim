local M = {}
local utils = require'utils'

M.setup = function(opts)
	local DEFAULT_OPTS = {
		current_line_opts = {
			display = true,
			show_keywords = true, --whether to show keywords like if, let, match, etc
			descriptor_length = -1, --how many characters of a condition to show. e.g. if <<a == b>>
		},
		other_line_opts = {
			display = true,
			show_keywords = true,
			descriptor_length = 0,
		}
	}

	M.config = vim.tbl_deep_extend('force', DEFAULT_OPTS, opts or {})

	require'closing-context'.write_context(M.config)
end

M.write_context = function(opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local filetype = vim.bo[bufnr].filetype
	if filetype == "html" then
		require'html'.context(opts, bufnr)
	elseif filetype == "rust" then
		require'rust'.context(opts, bufnr)
	elseif filetype == "javascript" then
		require'javascript'.context(opts, bufnr)
	end
end

M.clear_context = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local ns_id = vim.api.nvim_get_namespaces()['closing-context']
	if ns_id ~= nil then
		vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	end
end

M.rewrite_context = function()
	M.clear_context()
	M.write_context(M.config)
end

vim.api.nvim_create_autocmd({
	'BufWritePost', 'BufReadPost', 'BufEnter', 'BufWinEnter',
	'CursorMoved', 'TabEnter', 'TextChanged', 'TextChangedI' }, {
	pattern = {"*.html", "*.rs", "*.js"},
	command = "lua require'closing-context'.rewrite_context()",
})

-- User command handler
M.command_handler = function(args)
	local command = args.args
	utils.inspect(command)
	if command == "write_context" then
		M.write_context(M.config)
	elseif command == "clear_context" then
		M.clear_context()
	elseif command == "rewrite_context" then
		M.rewrite_context()
	else
			print("Invalid subcommand. Use ':ClosingContext' followed by 'write_context', 'clear_context', or 'rewrite_context'.")
	end
end

vim.api.nvim_create_user_command('ClosingContext', M.command_handler, {
	nargs = 1,
	complete = function(_, _, _)
			return { 'clear_context', 'rewrite_context', 'write_context' }
	end,
})

return M
