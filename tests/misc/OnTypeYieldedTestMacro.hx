package misc;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ComplexTypeTools;
import haxe.macro.ExprTools;

class OnTypeYieldedTestMacro {

    #if (macro && yield)
    private static function init () {
        yield.parser.Parser.onTypeYielded("misc.OnTypeYieldedTests.SimpleModificationType", onSimpleModificationTypeReturned);
        yield.parser.Parser.onTypeYielded("misc.OnTypeYieldedTests.ReparsingType", onYieldedTypeReturned);
    }

    private static function onSimpleModificationTypeReturned (returnedValue:Expr):Null<Expr> {
        return macro null;
    }

    private static function onYieldedTypeReturned (returnedValue:Expr):Null<Expr> {
        
        return macro function () {
            @yield return 1;
            @yield return 2;
        };

    }
    #end

}