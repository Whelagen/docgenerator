local lfs = require("lfs")
local utf8 = require("lua-utf8")

local M = {}

local function has_value(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end

	return false
end

local printt = function(tableau)
	print(vim.inspect(tableau))
end

-- see if the file exists
local file_exists = function(file)
	local f = io.open(file, "rb")
	if f then
		f:close()
	end
	return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local lines_from = function(file)
	if not file_exists(file) then
		return {}
	end
	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

local strptime = function(chaine)
	jour, mois, annee = utf8.match(chaine, "(%d%d) ([%a]+) (%d%d%d%d)")
	local code_mois = {
		janvier = 1,
		["février"] = 2,
		mars = 3,
		avril = 4,
		mai = 5,
		juin = 6,
		juillet = 7,
		["août"] = 8,
		septembre = 9,
		octobre = 10,
		novembre = 11,
		["décembre"] = 12,
	}
	print(jour, code_mois[mois], annee)
end

local titres = function(fichiers)
	local info_fichier = {}
	local nom = ""
	local header = {}
	for n, name in ipairs(fichiers) do
		nom = name
		local lignes = lines_from(name)
		local datation = string.match(lignes[1], "# (.+)")
		strptime(datation)
		info_fichier[name] = { date = datation }
		local header = {}
		local head = ""
		local flag = 0
		for _, titre in ipairs(lignes) do
			if flag == 1 and string.match(titre, "## ") then
				flag = 0
			end
			if flag == 1 then
				table.insert(header[head], titre)
			end
			if string.match(titre, "## ") then
				head = string.match(titre, "## .+ (.+) —") or string.match(titre, "## (.+)")
				-- print("head"..head)
				header[head] = {}
				flag = 1
			end
		end
		info_fichier[nom].header = header
	end
	-- printt(info_fichier)
	return info_fichier
end

local on_exit = function(job_id, code, _)
	if code == 0 then
		print("Conversion du document effectuée")
	else
		print("Erreur dans la conversion : " .. job_id:stderr_result()[1])
	end
end

-- Capable de créer un fichier odt à partir d'un md
M.genseance = function(type)
	local extention = ""
	if type == "doc" then
		extention = ".odt"
	elseif type == "tex" then
		extention = ".pdf"
	end

	local nom = vim.fn.expand("%:p:r")
	local cwd = vim.fn.getcwd()
	vim.cmd([[:cd %:p:h]])
	os.execute("cd")
	local Job = require("plenary.job")
	Job:new({
		command = "pandoc",
		args = {
			-- "--template", "style.xml",
			"-o",
			nom .. extention,
			vim.fn.expand("%:p"),
		},
		on_exit = on_exit,
	}):start()
	vim.cmd(":cd " .. cwd)
end

M.seancesenfants = function()
	-- local cwd = vim.fn.getcwd()
	local racine = vim.fn.expand("%:p:h")
	-- print(racine)
	-- Liste des fichiersa

	-- Construction du tableau des fichiers à traiter Classer par ordre chronologique
	local fichiers = {}
	for file in lfs.dir(racine) do
		if file ~= ".." and file ~= "." and string.match(file, "%d%d%d%d%-%d%d%-%d%dSéance.md$") then
			table.insert(fichiers, racine .. "/" .. file)
		end
	end
	table.sort(fichiers)
	-- printt(fichiers)
	local titre = titres(fichiers)
	-- printt(fichiers)
	local prenom = {}
	for k, v in pairs(titre) do
		for w, x in pairs(v.header) do
			if not has_value(prenom, w) then
				table.insert(prenom, w)
			end
		end
	end
	printt(prenom)

	local contenu = ""
	for _, pren in pairs(prenom) do
		contenu = contenu .. "# " .. pren
		contenu = contenu .. "\n"
		for _, v in pairs(titre) do
			contenu = contenu .. "## " .. v.date
			contenu = contenu .. "\n"
			for w, x in pairs(v.header) do
				for k, l in pairs(x) do
					if l == "" then
						contenu = contenu .. " \n"
					end
					if w == pren then
						contenu = contenu .. l
					end

					contenu = contenu .. "\n"
				end
			end
		end
	end
	-- Écrire le fichier
	-- print(contenu)
	local racine = vim.fn.expand("%:p:h")
	local note_enfant = racine .. "/noteEnfant.md"
	local file = io.open(note_enfant, "w")
	file:write(contenu)
	file:close()
end

return M
