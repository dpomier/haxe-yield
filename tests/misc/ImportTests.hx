package misc;

import utest.Assert;
import pack.pack1.MiscFunctions;
import pack.pack1.MoreMiscFunctions;
import pack.pack1.MoreMiscFunctions.a0 as funcA0;
import pack.pack1.MoreMiscFunctions.a1;
import pack.pack1.MoreMiscFunctions.MoreMiscFunctions3.*;
import pack.pack3.SomeFunctions.*;
import pack.pack2.*;
import yield.Yield;

@:access(pack.pack1.MoreMiscFunctions.priv)
class ImportTests implements Yield
{

	public function new() {
		
	}
	
	function testSimpleImport () {
		var it = simpleImport("Patrick");
		
		Assert.isTrue(it.hasNext());
		Assert.equals("hello!", it.next());
		Assert.isTrue(it.hasNext());
		Assert.equals("hello Toto!", it.next());
		Assert.isTrue(it.hasNext());
		Assert.equals("hello Patrick!", it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function simpleImport (name:String): Iterator<String> {
		
		#if (neko || js || php || python || lua)
		var msg = MiscFunctions.hello();
		#else
		var msg:String = MiscFunctions.hello();
		#end
		
		@yield return msg;
		@yield return MiscFunctions.sayHello("Toto");
		@yield return MiscFunctions.sayHello(name);
	}
	
	function testImportField () {
		var it = importField();
		
		Assert.isTrue(it.hasNext());
		Assert.equals(1, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function importField (): Iterator<Int> {
		@yield return a1("");
	}
	
	function testAsImport () {
		var it = asImport();
		
		Assert.isTrue(it.hasNext());
		Assert.equals(0, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function asImport (): Iterator<Int> {
		@yield return funcA0("");
	}
	
	function testAccessField () {
		var it = accessField();
		
		Assert.isTrue(it.hasNext());
		Assert.equals(100, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function accessField (): Iterator<Int> {
		@yield return pack.pack1.MoreMiscFunctions.priv("");
	}
	
	function testAccessField2 () {
		var it = accessField2();
		
		Assert.isTrue(it.hasNext());
		Assert.equals(200, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	@:access(pack.pack1.MoreMiscFunctions.priv2)
	function accessField2 (): Iterator<Int> {
		@yield return pack.pack1.MoreMiscFunctions.priv2("");
	}
	
	//function testImportAllowedField () {
		//var it = importAllowedField();
		//
		//Assert.isTrue(it.hasNext());
		//Assert.equals(9, it.next());
		//Assert.isFalse(it.hasNext());
	//}
	//
	//function importAllowedField (): Iterator<Int> {
		//@yield return misc.pack.MoreMiscFunctions.MoreMiscFunctionsPriv.d0("");
	//}
	
	function testAllField () {
		var it = allField();
		
		Assert.isTrue(it.hasNext());
		Assert.equals(5, it.next());
		Assert.equals(6, it.next());
		Assert.equals(7, it.next());
		Assert.equals(8, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function allField (): Iterator<Int> {
		@yield return c0("");
		@yield return c1("");
		@yield return c2("");
		@yield return c3("");
	}
	
	function testAllField2 () {
		var it = allField2();
		
		Assert.isTrue(it.hasNext());
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function allField2 (): Iterator<Int> {
		@yield return f0("");
		@yield return f1("");
	}
	
	function testAllModule () {
		var it = allModule();
		Assert.isTrue(it.hasNext());
		Assert.equals("toto1", it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function allModule () {
		@yield return MiscYielded.inlineMethod2("toto").next();
	}
	
	function testUsingTypedef () {
		
		var it = usingTypedef0();
		Assert.equals(0, it.next());
		
		it = usingTypedef1();
		Assert.equals(1, it.next());
		
		it = usingTypedef2();
		Assert.equals(2, it.next());
		
		it = usingTypedef3();
		Assert.equals(3, it.next());
		
		//it = usingTypedef4();
		//Assert.equals(4, it.next());
		
		//it = usingTypedef5();
		//Assert.equals(5, it.next());
		
		//it = usingTypedef6();
		//Assert.equals(6, it.next());
	}
	
	function usingTypedef0 ():DynamicAlias {
		@yield return 0;
	}
	
	function usingTypedef1 ():DynamicIterator {
		@yield return 1;
	}
	
	function usingTypedef2 ():Enumerator<Int> {
		@yield return 2;
	}
	
	function usingTypedef3<T:Int> ():Iterator<T> {
		@yield return cast 3;
	}
	
	//function usingTypedef4<T:Int> ():Enumerator<T> {
		//@yield return cast 4;
	//}
	
	//function usingTypedef5<T:Enumerator<Int>> ():T {
		//@yield return cast 5;
	//}
	
	//function usingTypedef6<B:Int, T:Enumerator<B>> ():T {
		//@yield return cast 6;
	//}
	
}

typedef Enumerator<T> = Iterator<T>;
typedef DynamicAlias  = Dynamic;
typedef DynamicIterator = Iterator<Dynamic>;