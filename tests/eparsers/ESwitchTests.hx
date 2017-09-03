package eparsers;

import haxe.macro.Expr;
import haxe.unit.TestCase;
import yield.Yield;

class ESwitchTests extends TestCase implements Yield
{

	public function new() 
	{
		super();
	}
	
	function testBase () {
		
		var it = base(Data.None);
		assertEquals("none", it.next());
		var it = base(Data.WrappedMessages({ get: function () return "foo" }, null));
		assertEquals("foo", it.next());
	}
	
	function base (data:Data) {
		
		var message:String;
		
		switch (data) {
			case Data.None:
			case Data.Message(msg):
			case Data.WrappedMessages(msg1, msg2):
			case _:
		}
		
		switch (data) {
			case Data.None: message = "none";
			case Data.Message(msg): message = "";
			case Data.WrappedMessage(msg1): message = "";
			default: message = "";
		}
		
		switch (data) {
			case Data.None:
			case Data.Message(msg):
			case Data.WrappedMessage(msg1):
			case Data.Messages(msg, msg2):
			case Data.WrappedMessages(_.get() => msg1, msg2g):
				message = msg1;
		}
		
		@yield return message;
	}
	
	
	function testYielded () {
		
		var it = yielded(Data.WrappedMessages({ get: function () return "foo" }, { get: function () return 3 }));
		assertEquals("foo", it.next());
		assertEquals("foo", it.next());
		assertEquals("foo", it.next());
		assertEquals(5, it.next());
		
		var it = yielded(Data.None);
		assertEquals(1, it.next());
		assertEquals(1, it.next());
		assertFalse(it.hasNext());
	}
	
	function yielded (data:Data):Iterator<Dynamic> {
		
		var message:String;
		
		var lastVar:Int = 0;
		
		switch (data) {
			case Data.None:
				
				@yield return 1;
				lastVar = 1;
				
			case Data.Message(msg):
				
				@yield return 2;
				
				@yield return 20;
				lastVar = 2;
				
			case Data.WrappedMessage(_.get() => msg):
				
				@yield return msg;
				@yield return msg;
				lastVar = 3;
				
			case Data.Messages(msg1, msg2Z):
				
				lastVar = 4;
				
			case Data.WrappedMessages(msg1, msg2):
				
				for (i in 0...msg2.get()) {
					@yield return msg1.get();
				}
				lastVar = 5;
		}
		
		@yield return lastVar;
	}
	
	
	function testGuard () {
		
		var it = guard(Data.None, 5);
		assertEquals(1, it.next());
		assertEquals(10, it.next());
		assertFalse(it.hasNext());
		
		var it = guard(Data.None, 3);
		assertEquals(2, it.next());
		assertEquals(20, it.next());
		assertFalse(it.hasNext());
		
		var it = guard(Data.None, 4);
		assertEquals(3, it.next());
		assertEquals(30, it.next());
		assertFalse(it.hasNext());
	}
	
	function guard (data:Data, count:Int):Iterator<Dynamic> {
		
		var lastVar:Int = 0;
		
		switch (data) {
			
			case Data.None if (count > 4):
				
				@yield return 1;
				lastVar = 10;
				
			case Data.None if (count < 4):
				
				@yield return 2;
				lastVar = 20;
				
			case Data.None if (count == 4):
				
				@yield return 3;
				lastVar = 30;
				
			case _:
				lastVar = 100;
				
			default: 
				lastVar = 200;
		}
		
		@yield return lastVar;
	}
	
	function testReturnedValue () {
		
		var it = returnedValue(true);
		assertTrue(it.hasNext());
		assertEquals(1, it.next());
		assertEquals(3, it.next());
		assertFalse(it.hasNext());
		
		var it = returnedValue(false);
		assertTrue(it.hasNext());
		assertEquals(2, it.next());
		assertEquals(4, it.next());
		assertFalse(it.hasNext());
		
	}
	
	function returnedValue (v:Bool) {
		
		var a:Int = switch (v) {
			case true:
				1;
			case false:
				2;
		};
		
		@yield return a;
		
		@yield return switch (v) {
			case true:
				3;
			case false:
				4;
		};
	}
	
	function testComplexReturnedValue () {
		
		var it = complexReturnedValue(Data.None, 3);
		assertTrue(it.hasNext());
		assertEquals(20, it.next());
		assertEquals(10, it.next());
		assertFalse(it.hasNext());
		
		var it = complexReturnedValue(Data.WrappedMessages(null, {get: function () return 50}), 5);
		assertTrue(it.hasNext());
		assertEquals(100, it.next());
		assertEquals(50, it.next());
		assertFalse(it.hasNext());
		
	}
	
	function complexReturnedValue (data:Data, count:Int) {
		
		var a:Int = switch (data) {
			case Data.None if (count < 4): 20;
			case Data.None if (count == 4):	30;
			case _: 100;
			default: 200;
		};
		
		@yield return a;
		
		@yield return switch (data) {
			case Data.None: 10;
			case Data.WrappedMessages(_, _.get() => v): v;
			case _: 100;
			default: 200;
		};
	}
	
	function testNestedReturnedValue () {
		
		var it = nestedReturnedValue(Data.WrappedMessages(null, { get:function () return 3 }));
		assertTrue(it.hasNext());
		
		var func = it.next();
		var subIt = func();
		
		assertTrue(subIt.hasNext());
		assertEquals(3, subIt.next());
		assertEquals(3, subIt.next());
		assertEquals(3, subIt.next());
		assertFalse(subIt.hasNext());
		
		assertFalse(it.hasNext());
		
	}
	
	function nestedReturnedValue (data:Data) {
		
		@yield return switch (data) {
			case Data.None: 10;
			case Data.WrappedMessages(_, _.get() => v): 
				function () {
					@yield return v;
					@yield return v;
					{ @yield return v; }
				};
			case _: 100;
			default: 200;
		};
	}
	
	function testNestedReturnedValue2 () {
		
		var it = nestedReturnedValue2(
			Data.WrappedMessages({ get:function () return "one" }, { get:function () return 3 }),
			Data.Messages("two", 4)
		);
		
		assertTrue(it.hasNext());
		var funcGetFirst = it.next();
		assertTrue(Reflect.isFunction(funcGetFirst));
		var firstSubIt = funcGetFirst();
		assertFalse(it.hasNext());
		
		assertTrue(firstSubIt.hasNext());
		var funcGetSecond = firstSubIt.next();
		assertTrue(Reflect.isFunction(funcGetSecond));
		var secondSubIt:Iterator<Dynamic> = funcGetSecond();
		assertFalse(firstSubIt.hasNext());
		
		assertTrue(secondSubIt.hasNext());
		assertEquals(3, secondSubIt.next());
		assertEquals(4, secondSubIt.next());
		assertEquals("two", secondSubIt.next());
		assertFalse(secondSubIt.hasNext());
		
	}
	
	function nestedReturnedValue2 (data:Data, data2:Data) {
		
		@yield return switch (data) {
			case Data.None: 10;
			case Data.WrappedMessages(_.get() => s, _.get() => v): 
				
				function () {
					@yield return switch (data2) {
						case Data.None: 10;
						case Data.Messages(s, v2): 
							
							function () {
								
								@yield return v;
								@yield return v2;
								
								@yield return s;
							};
							
						case _: 100;
						default: 200;
					};
				};
				
			case _: 100;
			default: 200;
		};
	}
	
	function testReferenceAsVar () {
		var it = referenceAsVar(Data.Message("foo"));
		
		assertTrue(it.hasNext());
		assertEquals("foo", it.next());
		assertEquals("foo", it.next());
		assertEquals("foofoo", it.next());
		assertFalse(it.hasNext());
	}
	
	function referenceAsVar (data:Data) {
		
		var a:Void->String = function () return null;
		var b:Void->Void = function () {};
		
		var rs:Void->Iterator<String> = switch (data) {
			
			case Message(v): 
				
				function () {
					
					a = function () {
						return v;
					};
					b = function () {
						#if !python // cf. issue #6551
						v += v;
						#else
						var s:String = v;
						s += s;
						v = s;
						#end
					};
					
					@yield return a();
				};
				
			case _: function () return null;
		};
		
		var it:Iterator<String> = rs();
		@yield return it.next();
		
		@yield return a();
		b();
		@yield return a();
	}
	
}

enum Data {
	None;
	Message(msg:String);
	WrappedMessage(msg:Getter<String>);
	Messages(msg1:String, msg2:Int);
	WrappedMessages(msg1:Getter<String>, msg2:Getter<Int>);
}

typedef Getter<T> = {
	function get (): T;
}