local html = {}

local function split_string(inputstr, sep)
	if sep == nil then
					sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
					table.insert(t, str)
	end
	return t
end

html.context = function(opts, bufnr)
	local ns_id = vim.api.nvim_create_namespace('closing-context')
	local root = vim.treesitter.get_parser(bufnr, 'html'):parse()[1]:root()

	local function get_text(node)
		return vim.treesitter.get_node_text(node, bufnr)
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	local tag_with_attributes_query = vim.treesitter.query.parse('html', [[
		(element
			(start_tag
				(attribute)+
			) @start_tag
			(end_tag
				(tag_name) @end_tag_text
			)
		)
	]])

	local attributes_query = vim.treesitter.query.parse('html', [[
		(attribute
			(attribute_name) @attribute_name
			(quoted_attribute_value
				(attribute_value) @attribute_value
			)
		)
	]])

	for _, html_node in tag_with_attributes_query:iter_matches(root, bufnr, 0, -1) do
		local start_tag_range = {html_node[1]:range()}
		local end_tag_range = {html_node[2]:range()}
		print(vim.inspect(start_tag_range) .. " " .. vim.inspect(end_tag_range))
		if start_tag_range[3] ~= end_tag_range[3] then
			-- Get the attributes and format them into a css selector
			local selector_text = ""
			for _, attribute_node in attributes_query:iter_matches(html_node[1], bufnr, 0, -1) do
				local an1 = get_text(attribute_node[1])
				local an2 = get_text(attribute_node[2])
				if an1 == "id" then
					selector_text = "#" .. an2 .. selector_text
				elseif an1 == "class" then
					local split_classes = split_string(an2, " ")
					for _, class_string in ipairs(split_classes) do
						selector_text = selector_text .. "." .. class_string
					end
				else
					selector_text = selector_text .. "[" .. an1 .. "=\"" .. an2 .. "\"]"
				end
			end

			vim.api.nvim_buf_set_extmark(bufnr, ns_id, end_tag_range[3], end_tag_range[4], {
				virt_text = {{selector_text, 'Comment'}},
				virt_text_pos = 'inline',
			})
		end
	end
end

return html
