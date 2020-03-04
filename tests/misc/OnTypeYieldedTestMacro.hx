package misc;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ComplexTypeTools;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import yield.parser.Parser;

class OnTypeYieldedTestMacro {

    #if (macro && yield)
    private static function init () {
        Parser.onYield(onYield);
    }

    static function onYield (e:Expr, ?t:ComplexType):Null<YieldedExpr> {

        var followed:Null<String> = if (t != null) {
            ComplexTypeTools.toString(t);
        } else try {
            ComplexTypeTools.toString(TypeTools.toComplexType(Context.typeof(e)));
        } catch (_:Dynamic) {
            null;
        };

        return switch followed {
            case "misc.OnTypeYieldedTests.SimpleModificationType": macro 3;
            case "misc.OnTypeYieldedTests.ReparsingType": macro function () {
                @yield return 1;
                @yield return 2;
            };
            case "misc.OnTypeYieldedTests.ReEntranceType": macro new misc.OnTypeYieldedTests.SimpleModificationType();
            case "misc.OnTypeYieldedTests.LoopType": 
                switch e {
                    case (macro @coroutine_test_loop($v) $expr):
                        var loopCount = switch v.expr { case EConst(CInt(v)): Std.parseInt(v); case _: throw "wrong loop count"; };
                        if (loopCount == 4)
                            macro "done";
                        else
                            macro @coroutine_test_loop($v{loopCount + 1}) $expr;
                    case _:
                        macro @coroutine_test_loop(0) $e;
                }
            case _: null;
        }

    }
    #end

}