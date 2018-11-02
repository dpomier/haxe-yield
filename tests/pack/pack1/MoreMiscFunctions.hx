package pack.pack1;
import misc.ImportTests;

class MoreMiscFunctions
{
	public static function a0 (s:String) return 0;
	public static function a1 (s:String) return 1;
	public static function a2 (s:String) return 2;
	private static function priv (s:String) return 100;
	private static function priv2 (s:String) return 200;

	public static function UppercaseFunction () return 42;
}

class MoreMiscFunctions2
{
	public static function b0 (s:String) return 3;
	public static function b1 (s:String) return 4;
}

class MoreMiscFunctions3
{
	public static function c0 (s:String) return 5;
	public static function c1 (s:String) return 6;
	public static function c2 (s:String) return 7;
	public static function c3 (s:String) return 8;
}

@:allow(misc.ImportTests)
class MoreMiscFunctionsPriv
{
	private static function d0 (s:String) return 9;
}

class MoreMiscFunctionsPriv2
{
	private static function e0 (s:String) return 10;
}