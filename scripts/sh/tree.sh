tree -sfDF --sort=mtime -o tree.txt && vim -c '%s/^.\{-}\[/[/g' -c 'wq' tree.txt
