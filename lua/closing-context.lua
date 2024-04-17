local M = {}
local utils = require'utils'
local TYPES = utils.TYPES

M.setup = function(opts)
	local DEFAULT_OPTS = {
		current_line = {
			display = true, --whether or not to display the text
			show_keywords = true, --whether to show keywords like if, let, match, etc
			descriptor_length = -1, --how many characters of a condition to show. e.g. if <<a == b>>
		},
		other_line = {
			display = true,
			show_keywords = true,
			descriptor_length = 0,
		},
		FUNCTION = {
			other_line = {
				descriptor_length = -1, --this will override the base other_line to show the function names at all times
			},
		},
		VARIABLE = {
			other_line = {
				descriptor_length = -1, --this will override the base other_line to show variable names at all times
			},
		},
	}

	M.config = vim.tbl_deep_extend('force', DEFAULT_OPTS, opts or {})

	local defaults = {
		current_line = {},
		other_line = {},
	}

	defaults.current_line = DEFAULT_OPTS.current_line
	defaults.other_line = DEFAULT_OPTS.other_line

	-- expand base keyword options
	for key, _ in pairs(M.config) do
		if TYPES[key] ~= nil then
			M.config[key].current_line = vim.tbl_extend('force', defaults.current_line, M.config[key].current_line or {})
			M.config[key].other_line = vim.tbl_extend('force', defaults.other_line, M.config[key].other_line or {})
			defaults[key] = M.config[key]
		end
	end

	-- expand lanauge specific options
	for key, config in pairs(M.config) do
		if TYPES[key] == nil and key ~= "current_line" and key ~= "other_line" then
			M.config[key] = vim.tbl_deep_extend('force', defaults, config or {})
		end
	end

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
	elseif filetype == "lua" then
		require'lua'.context(opts, bufnr)
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
	pattern = {"*.html", "*.rs", "*.js", "*.lua"},
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

