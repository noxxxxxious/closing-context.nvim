local utils = {}

utils.inspect = function(value)
	print(vim.inspect(value))
end

utils.write_vtext = function(opts, bufnr, ns_id, block_node, keyword, condition)
	local end_coordinates = {block_node:range()}
	-- don't print if 1 line
	if end_coordinates[1] == end_coordinates[3] then
		return
	end

	-- get cursor line to see which set of options to use
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1
	if cursor_line == end_coordinates[3] then
		opts = opts.current_line_opts
	else
		opts = opts.other_line_opts
	end

	if opts.display == false then
		return
	end

	if opts.show_keywords == true then
		keyword = "/" .. keyword .. " "
	else
		keyword = "/"
	end

	if opts.descriptor_length == 0 then
		condition = ""
	elseif opts.descriptor_length > 0 then
		condition = string.sub(condition, 1, opts.descriptor_length) .. "..."
	end

	local vtext = keyword .. condition

	vim.api.nvim_buf_set_extmark(bufnr, ns_id, end_coordinates[3], end_coordinates[4], {
		virt_text = {{vtext, 'Comment'}},
		virt_text_pos = 'eol',
	})
end

utils.split_string = function(inputstr, sep)
	if sep == nil then
					sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
					table.insert(t, str)
	end
	return t
end

return utils
