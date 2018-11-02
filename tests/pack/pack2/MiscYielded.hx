package pack.pack2;

@:yield
class MiscYielded
{
	public static inline function inlineMethod2 (s:String) {
		@yield return s+1;
		@yield return s+2;
		@yield return s+3;
	}
}