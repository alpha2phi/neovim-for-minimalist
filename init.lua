-- Indicate first time installation
local packer_bootstrap = false

-- packer.nvim configuration
local conf = {
	profile = {
		enable = true,
		threshold = 0, -- the amount in ms that a plugins load time must be over for it to be included in the profile
	},

	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
}

-- Check if packer.nvim is installed
-- Run PackerCompile if there are changes in this file
local function packer_init()
	local fn = vim.fn
	local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
	if fn.empty(fn.glob(install_path)) > 0 then
		packer_bootstrap = fn.system({
			"git",
			"clone",
			"--depth",
			"1",
			"https://github.com/wbthomason/packer.nvim",
			install_path,
		})
		vim.cmd([[packadd packer.nvim]])
	end

	local packerGrp = vim.api.nvim_create_augroup("packer_user_config", { clear = true })
	vim.api.nvim_create_autocmd(
		{ "BufWritePost" },
		{ pattern = "plugins.lua", command = "source <afile> | PackerCompile", group = packerGrp }
	)
end

-- Plugins
local function plugins(use)
	use({ "wbthomason/packer.nvim" })

	use({ "echasnovski/mini.nvim" })

	-- Bootstrap Neovim
	if packer_bootstrap then
		print("Restart Neovim required after installation!")
		require("packer").sync()
	end
end

-- Init and start packer
packer_init()
local packer = require("packer")

packer.init(conf)
packer.startup(plugins)
