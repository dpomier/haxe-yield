package eparsers;


import yield.Yield;

class ETryTests implements Yield
{

	public function new() {
		super();
	}
	
	function testSimpleTry () {
		var it = simpleTry();
		
		var error = 0;
		
		try {
			it.next();
		} catch (err:Dynamic) {
			error = err;
		}
		
		assertEquals(1, error);
	}
	
	function simpleTry ():Iterator<Int> {
		
		var a = 1;
		try throw a;
		@yield return a;
	}
	
	function testTryY () {
		var it = tryY();
		
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(25, it.next());
		assertFalse(it.hasNext());
	}
	
	function tryY ():Iterator<Int> {
		
		var a = 10;
		
		try {
			a += 5;
			@yield return 0;
			@yield return 1;
			a += 10;
			
		} catch (err:Dynamic) {
			
		}
		
		@yield return a;
	}
	
	function testTryYThrow () {
		var it = tryYThrow();
		
		assertEquals(0, it.next());
		assertEquals(1, it.next());
		assertEquals(2, it.next());
		assertEquals(10, it.next());
		assertFalse(it.hasNext());
	}
	
	function tryYThrow ():Iterator<Int> {
		
		var a = 10;
		
		try {
			@yield return 0;
			@yield return 1;
			@yield return 2;
			throw null;
			@yield return 3;
			@yield return 4;
			
		} catch (err:Dynamic) { }
		
		@yield return a;
	}
	
	function testCatchY () {
		var it = catchY();
		
		assertEquals(42, it.next());
		assertFalse(it.hasNext());
	}
	function catchY ():Iterator<Int> {
		
		var a = 0;
		
		try {
			
			a += 42;
			
		} catch (err:String) {
			
			a += 1;
			@yield return 2;
			a += 3;
			@yield return 4;
			a += 4;
			
		} catch (err:Dynamic) { }
		@yield return a;
	}
	
	function testCatchY2 () {
		var it = catchY2();
		
		assertEquals(80, it.next());
		assertEquals(60, it.next());
		assertEquals(42, it.next());
		assertFalse(it.hasNext());
	}
	function catchY2 ():Iterator<Int> {
		
		var a = 0;
		
		try {
			
			a += 20;
			@yield return 80;
			@yield return 60;
			a += 22;
			
		} catch (err:String) {
			
			a += 1;
			@yield return 2;
			a += 3;
			@yield return 4;
			a += 4;
			
		} catch (err:Dynamic) { }
		@yield return a;
	}
	
	function testCatchYThrow () {
		var it = catchYThrow();
		
		assertEquals(2, it.next());
		assertEquals(4, it.next());
		assertEquals(8, it.next());
		assertFalse(it.hasNext());
	}
	function catchYThrow ():Iterator<Int> {
		
		var a = 0;
		
		try {
			
			throw "error";
			
		} catch (err:String) {
			
			a += 1;
			@yield return 2;
			a += 3;
			@yield return 4;
			a += 4;
			
		} catch (err:Dynamic) {
			
			a += 20;
			var n:Null<Int> = null;
			var lnull:Int   = n;
			@yield return lnull;
			@yield return lnull;
			a += 30;
			
		}
		@yield return a;
	}
	
	function testGettingError () {
		var it = gettingError();
		
		assertEquals("foobar", it.next());
		assertEquals(5, it.next());
		assertEquals(null, it.next());
		assertFalse(it.hasNext());
	}
	function gettingError ():Iterator<Dynamic> {
		
		try {
			
			throw "foobar";
			
		} catch (err:String) {
			
			@yield return err;
			
		} catch (err:Dynamic) { }
		
		try {
			
			throw 5;
			
		} catch (err:String) {
			
		} catch (err:Dynamic) {
			@yield return err;
		}
		
		try {
			
		} catch (err:Dynamic) {
			@yield return 10;
		}
		
		@yield return null;
	}
	
	function testReturnedValue () {
		
		var it = returnedValue("string");
		assertTrue(it.hasNext());
		assertEquals("1", it.next());
		assertEquals("2", it.next());
		assertFalse(it.hasNext());
		
		it = returnedValue(10);
		assertTrue(it.hasNext());
		assertEquals("2", it.next());
		assertEquals("4", it.next());
		assertFalse(it.hasNext());
		
		it = returnedValue(false);
		assertTrue(it.hasNext());
		assertEquals("3", it.next());
		assertEquals("6", it.next());
		assertFalse(it.hasNext());
	}
	
	function returnedValue (err:Dynamic) {
		
		var a:String = try {
			throw err;
		} catch (err:String) {
			"1";
		} catch (err:Bool) {
			"3"; // prevents unification of Bool with Int
		} catch (err:Int) {
			"2";
		} catch (err:Dynamic) {
			"3";
		};
		
		@yield  return a;
		
		@yield return try {
			throw err;
		} catch (err:String) {
			"2";
		} catch (err:Bool) {
			"6"; // prevents unification of Bool with Int
		} catch (err:Int) {
			"4";
		} catch (err:Dynamic) {
			"6";
		};
	}
	
	function testInitialization () {
		var it = initialization();
		assertTrue(it.hasNext());
		assertEquals(2, it.next());
		try {
			it.next();
			assertTrue(false);
		} catch (err:Dynamic) {
			assertTrue(true);
		}
		assertFalse(it.hasNext());
	}
	
	function initialization () {
		
		var v:Int;
		
		try {
			
			v = 1;
			throw 5;
			
		} catch (err:String) {
			throw null;
		} catch (err:Int) {
			v = 2;
		} catch (err:Dynamic) {
			v = 3;
			@yield return err;
		}
		
		@yield return v;
		
		var v:Int;
		
		throw null;
		
		@yield return v;
	}

	function testTryInFor () {

		tryInFor(); // check compilation

		assertTrue(true);
	}

	function tryInFor ():Iterator<String> {
		
		var num = 3;

		for (i in 0...num) {

			try {

			}
		}

		@yield break;
	}
}