cscript c:\windows\system32\slmgr.vbs /dlv
cscript "$env:SystemRoot\system32\slmgr.vbs" /skms kms.core.windows.net:1688
cscript "$env:SystemRoot\system32\slmgr.vbs" /act-type 2
cscript "$env:SystemRoot\system32\slmgr.vbs" /ato
cscript c:\windows\system32\slmgr.vbs /dlv