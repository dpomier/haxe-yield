package misc;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ComplexTypeTools;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;

class OnTypeYieldedTestMacro {

    #if (macro && yield)
    private static function init () {
        yield.parser.Parser.onYield(onYield);
    }

    static function onYield (e:Expr, ?t:ComplexType):Null<Expr> {

        var followed:Null<String> = if (t != null) {
            ComplexTypeTools.toString(t);
        } else try {
            ComplexTypeTools.toString(TypeTools.toComplexType(Context.typeof(e)));
        } catch (_:Dynamic) {
            null;
        };

        return switch followed {
            case "misc.OnTypeYieldedTests.SimpleModificationType": macro null;
            case "misc.OnTypeYieldedTests.ReparsingType": macro function () {
                @yield return 1;
                @yield return 2;
            };
            case _: null;
        }

    }
    #end

}