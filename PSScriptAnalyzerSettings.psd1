@{
    ExcludeRules = @(
        # install.ps1 is an interactive installer; its progress is meant for the console
        'PSAvoidUsingWriteHost',
        # starship and zoxide document `init powershell | Invoke-Expression` as their setup
        'PSAvoidUsingInvokeExpression'
    )
}
