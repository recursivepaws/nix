local map = require("utils").map
return {
	--[[ "David-Kunz/jester",
  config = function()
    require("jester").setup({})
    map("n", "<leader>tf", function()
      vim.cmd("lua require('jester').run_file()")
    end)
  end, ]]
}

--[[ { "<leader>tn",

        ":lua require('').run.run()<CR>",
        desc = "Run nearest test",
        noremap = true,
        silent = true,
      },
      {
        "<leader>tf",
        ":lua require('neotest').run.run(vim.fn.expand('%'))<CR>",
        desc = "Run file tests",
      },
      {
        "<leader>ts",
        ":lua require('neotest').summary.toggle()<CR>",
        desc = "Toggle test summary",
      },
      {
        "<leader>tw",
        ":lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<CR>",
        desc = "Jest test watch",
      }, ]]
