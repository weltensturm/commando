
if $false:
    error should not be here
else:
    echo hi there

if $true:
    echo all is good

test = (fn:
    if $true:
        return 1
    error should not be here)

echo (test)