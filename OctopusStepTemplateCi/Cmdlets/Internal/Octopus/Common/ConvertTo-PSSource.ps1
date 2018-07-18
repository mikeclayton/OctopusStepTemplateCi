<#

.SYNOPSIS
    Serializes an object into a string containing PowerShell code that can be used to re-create the object.

.EXAMPLE

$myValue = @{ "myKey1" = "myValue1"; "myKey2" = @( "myItem1", "myItem2") };
$mySource = ConvertTo-PSSource -InputObject $myValue;
Write-DebugText $mySource;

"@{
    myKey1 = "myValue1"
    myKey2 = @(
        "myItem1",
        "myItem2"
    )
}"

#>
function ConvertTo-PSSource
{

    param
    (

        [Parameter(Mandatory=$false)]
        [object] $InputObject,

        [Parameter(Mandatory=$false)]
        [int] $IndentLevel = 0

    )

    $ErrorActionPreference = "Stop";
    Set-StrictMode -Version "Latest";

    function ConvertFrom-KeyValuePairs
    {
        param
        (
            [object] $InputObject,
            [string[]] $Keys
        )
        $source = new-object System.Text.StringBuilder;
        [void] $source.Append("@{");
        if( $Keys.Length -gt 0 )
        {
            [void] $source.AppendLine();
            foreach( $key in $Keys )
            {
                [void] $source.Append($baseIndent);
                [void] $source.Append($indent);
                [void] $source.Append((ConvertTo-PSSource -InputObject $key));
                [void] $source.Append(" = ");
                [void] $source.Append((ConvertTo-PSSource -InputObject $InputObject[$key] -IndentLevel ($IndentLevel + 1)));
                [void] $source.AppendLine();
            }
            [void] $source.Append($baseIndent);
        }
        [void] $source.Append("}");
        return $source.ToString();
    }

    function Test-RequiresEvalInArray
    {
        param
        (
            [object] $InputObject
        )
        # does the value need "eval" brackets when nested in an array?
        # e.g.
        #     @( $null );
        #     @( $true );
        #     @( @{ ... } );
        # vs
        #     @( (new-object [PSCustomObject] -Property @{ ... }) );
        switch( $true )
        {
            { $InputObject -eq $null } {
                return $false;
            }
            { $InputObject.GetType().IsValueType } {
                return $false;
            }
            { $InputObject -is [string] } {
                return $false;
            }
            { $InputObject -is [hashtable] } {
                return $false;
            }
            default {
                return $true;
            }
        }
    }

    $indent = " " * 4;
    $baseIndent = $indent * $IndentLevel;

    switch( $true )
    {

        { $InputObject -eq $null } {
            return "`$null";
        }

        { $InputObject -is [bool] } {
	    if( [bool] $InputObject )
	    {
                return "`$true";
	    }
	    else
	    {
                return "`$false";
	    }
        }

        { $InputObject -is [string] } {
            $value = $InputObject;
            $value = $value.Replace("``", "````");
            $value = $value.Replace("`"", "```"");
            $value = $value.Replace("`$", "```$");
            $value = $value.Replace("`r", "``r");
            $value = $value.Replace("`n", "``n");
            $value = $value.Replace("`t", "``t");
            $value = "`"$value`"";
            return $value;
        }

        { $InputObject -is [hashtable] } {
            $keys = @( $InputObject.Keys | sort-object );
            return (ConvertFrom-KeyValuePairs -InputObject $InputObject -Keys $keys);
        }

        { $InputObject -is [System.Collections.Specialized.OrderedDictionary] } {
            $source = new-object System.Text.StringBuilder;
            [void] $source.Append("[ordered]");
            [void] $source.Append(" ");
            [void] $source.Append((ConvertFrom-KeyValuePairs -InputObject $InputObject -Keys $InputObject.Keys));
            return $source.ToString();
        }

        { $InputObject -is [System.Management.Automation.PSCustomObject] } {
            $source = new-object System.Text.StringBuilder;
            $properties = @( $InputObject.psobject.Properties.GetEnumerator() );
            if( $properties.Length -eq 0 )
            {
                [void] $source.Append("new-object PSCustomObject");
            }
            else
            {
                [void] $source.AppendLine("new-object PSCustomObject -Property ([ordered] @{");
                foreach( $property in $InputObject.psobject.Properties )
                {
                    [void] $source.Append($baseIndent);
                    [void] $source.Append($indent);
                    [void] $source.Append((ConvertTo-PSSource -InputObject $property.Name));
                    [void] $source.Append(" = ");
                    [void] $source.Append((ConvertTo-PSSource -InputObject $property.Value -IndentLevel ($IndentLevel + 1)));
                    [void] $source.AppendLine();
                }
                [void] $source.Append($baseIndent);
                [void] $source.Append("})");
            }
            return $source.ToString();
        }

        { $InputObject.GetType().IsArray } {
            $source = new-object System.Text.StringBuilder;
            if( $InputObject.Length -eq 0 )
            {
                [void] $source.Append("@()");
            }
            else
            {
                [void] $source.Append("@(");
                [void] $source.AppendLine();
                for( $index = 0; $index -lt $InputObject.Length; $index++ )
                {
                    [void] $source.Append($baseIndent);
                    [void] $source.Append($indent);
                    $item     = $InputObject[$index];
                    $requiresEval = Test-RequiresEvalInArray -InputObject $item;
                    if( $requiresEval )
                    {
                        [void] $source.Append("(");
                    }
                    [void] $source.Append((ConvertTo-PSSource -InputObject $item -IndentLevel ($IndentLevel + 1)));
                    if( $requiresEval )
                    {
                        [void] $source.Append(")");
                    }
                    if( $index -lt ($InputObject.Length - 1) )
                    {
                        [void] $source.Append(",");
                    }
                    [void] $source.AppendLine();
                }
                [void] $source.Append($baseIndent);
                [void] $source.Append(")");
            }
            return $source.ToString();
        }

        default {
            return $InputObject.ToString();
        }

    }

}