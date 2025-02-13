# Initial Setup file for new systems
Remove-Item -Recurse -Force ~/AppData/Local/nvim
Remove-Item -Recurse -Force ~/AppData/Local/nvim-data
New-Item -Path "$HOME\AppData\Local\nvim" -ItemType SymbolicLink -Target "$pwd"
