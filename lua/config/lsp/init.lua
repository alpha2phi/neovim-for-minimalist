local servers = {
	sumneko_lua = {
		settings = {
			Lua = {
				runtime = {
					version = "LuaJIT",
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

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

local function keymappings()
	print("Todo")
end

local function on_attach(client, bufnr)
	vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

	vim.api.nvim_buf_set_option(0, "formatexpr", "v:lua.vim.lsp.formatexpr()")

	if client.server_capabilities.definitionProvider then
		vim.api.nvim_buf_set_option(bufnr, "tagfunc", "v:lua.vim.lsp.tagfunc")
	end
end

local opts = {
	on_attach = on_attach,
	capabilities = capabilities,
	flags = {
		debounce_text_changes = 150,
	},
}

-- nvim-lsp-installer must be set up before nvim-lspconfig
require("nvim-lsp-installer").setup({
	ensure_installed = vim.tbl_keys(servers),
	automatic_installation = false,
})

local lspconfig = require("lspconfig")
for server_name, _ in pairs(servers) do
	local extended_opts = vim.tbl_deep_extend("force", opts, servers[server_name] or {})
	lspconfig[server_name].setup(extended_opts)
end
