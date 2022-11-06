local M = {}


local on_exit = function(job_id, code, _)
    if code == 0 then
        print("Conversion du document effectuée")
    else
        print("Erreur dans la conversion : " .. job_id:stderr_result()[1])
    end
end

-- Capable de créer un fichier odt à partir d'un md
M.genseance = function()
    local nom = vim.fn.expand("%:p:r")
    local cwd = vim.fn.getcwd()
    vim.cmd [[:cd %:p:h]]
    os.execute("cd")
    local Job = require'plenary.job'
    Job:new({
        command = "pandoc",
        args = {
        -- "--template", "style.xml",
        "-o", nom..".odt",
vim.fn.expand("%:p")

        },
        on_exit = on_exit,
    }):start()
    vim.cmd(":cd ".. cwd)


end


return M
