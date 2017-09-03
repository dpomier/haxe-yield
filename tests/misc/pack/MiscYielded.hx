package misc.pack;
import yield.Yield;

class MiscYielded implements Yield
{
	public static inline function inlineMethod2 (s:String) {
		@yield return s+1;
		@yield return s+2;
		@yield return s+3;
	}
}