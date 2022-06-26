local servers = {
	sumneko_lua = {
		settings = {
			Lua = {
				runtime = {
					version = "LuaJIT",
					-- Setup your lua path
					path = vim.split(package.path, ";"),
				},
				diagnostics = {
					globals = { "vim" },
				},
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
				},
				telemetry = { enable = false },
			},
		},
	},
}

local function on_attach(client, bufnr)
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
	vim.api.nvim_buf_set_option(0, "formatexpr", "v:lua.vim.lsp.formatexpr()")

	-- Configure key mappings
	-- require("config.lsp.keymaps").setup(client, bufnr)

	-- Configure highlighting
	-- require("config.lsp.highlighter").setup(client)

	-- tagfunc
	if client.server_capabilities.definitionProvider then
		vim.api.nvim_buf_set_option(bufnr, "tagfunc", "v:lua.vim.lsp.tagfunc")
	end
end

-- nvim-lsp-installer must be set up before nvim-lspconfig
require("nvim-lsp-installer").setup({
	ensure_installed = vim.tbl_keys(servers),
	automatic_installation = false,
})

local lspconfig = require("lspconfig")
for server_name, _ in pairs(servers) do
	local opts = vim.tbl_deep_extend("force", options, servers[server_name] or {})

	if server_name == "sumneko_lua" then
		opts = require("lua-dev").setup({ lspconfig = opts })
	end

	lspconfig[server_name].setup(opts)
end
