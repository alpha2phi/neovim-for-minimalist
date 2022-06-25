local api = vim.api
local g = vim.g
local opt = vim.opt
local cmd = vim.cmd
local fn = vim.fn
local keymap = vim.keymap.set

local packer_bootstrap = false -- Indicate first time installation

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

local function packer_init()
	-- Check if packer.nvim is installed
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
		cmd([[packadd packer.nvim]])
	end

	-- Run PackerCompile if there are changes in this file
	local packerGrp = api.nvim_create_augroup("packer_user_config", { clear = true })
	api.nvim_create_autocmd(
		{ "BufWritePost" },
		{ pattern = "init.lua", command = "source <afile> | PackerCompile", group = packerGrp }
	)
end

-- Plugins
local function plugins(use)
	use({ "wbthomason/packer.nvim" })
	use({
		"echasnovski/mini.nvim",
		config = function()
			require("config.starter").setup()
		end,
	})

	-- Bootstrap Neovim
	if packer_bootstrap then
		print("Restart Neovim required after installation!")
		require("packer").sync()
	end
end

-- Options
local function options()
	opt.hlsearch = false
	opt.number = true
	opt.relativenumber = true
	opt.hidden = true
	opt.mouse = "a"
	opt.breakindent = true
	opt.undofile = true
	opt.ignorecase = true
	opt.smartcase = true
	opt.updatetime = 250
	opt.signcolumn = "yes"
	opt.termguicolors = true

	-- Space as leader key
	keymap("", "<Space>", "<Nop>", { noremap = true, silent = true })
	g.mapleader = " "
	g.maplocalleader = " "

	-- Word wrap
	keymap("n", "k", "v:count == 0 ? 'gk' : 'k'", { noremap = true, expr = true, silent = true })
	keymap("n", "j", "v:count == 0 ? 'gj' : 'j'", { noremap = true, expr = true, silent = true })

	-- jk to ESC
	keymap("i", "jk", "<ESC>", { noremap = true, silent = true })

	-- Highlight on yank
	api.nvim_exec(
		[[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup end
]],
		false
	)
end

-- packer.nvim
packer_init()
local packer = require("packer")
packer.init(conf)
packer.startup(plugins)

-- Editor options
options()
