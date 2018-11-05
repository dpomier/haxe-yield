package eparsers;

import utest.Assert;
import haxe.macro.Expr;
import pack.enums.EnumB;
import pack.enums.*;

@:yield
class ESwitchTests extends utest.Test {
	
	function testBase () {
		
		var it = base(Data.None);
		Assert.equals("none", it.next());
		var it = base(Data.WrappedMessages({ get: function () return "foo" }, null));
		Assert.equals("foo", it.next());
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
		Assert.equals("foo", it.next());
		Assert.equals("foo", it.next());
		Assert.equals("foo", it.next());
		Assert.equals(5, it.next());
		
		var it = yielded(Data.None);
		Assert.equals(1, it.next());
		Assert.equals(1, it.next());
		Assert.isFalse(it.hasNext());
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
		Assert.equals(1, it.next());
		Assert.equals(10, it.next());
		Assert.isFalse(it.hasNext());
		
		var it = guard(Data.None, 3);
		Assert.equals(2, it.next());
		Assert.equals(20, it.next());
		Assert.isFalse(it.hasNext());
		
		var it = guard(Data.None, 4);
		Assert.equals(3, it.next());
		Assert.equals(30, it.next());
		Assert.isFalse(it.hasNext());
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
		Assert.isTrue(it.hasNext());
		Assert.equals(1, it.next());
		Assert.equals(3, it.next());
		Assert.isFalse(it.hasNext());
		
		var it = returnedValue(false);
		Assert.isTrue(it.hasNext());
		Assert.equals(2, it.next());
		Assert.equals(4, it.next());
		Assert.isFalse(it.hasNext());
		
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
		Assert.isTrue(it.hasNext());
		Assert.equals(20, it.next());
		Assert.equals(10, it.next());
		Assert.isFalse(it.hasNext());
		
		var it = complexReturnedValue(Data.WrappedMessages(null, {get: function () return 50}), 5);
		Assert.isTrue(it.hasNext());
		Assert.equals(100, it.next());
		Assert.equals(50, it.next());
		Assert.isFalse(it.hasNext());
		
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
		Assert.isTrue(it.hasNext());
		
		var func = it.next();
		var subIt = func();
		
		Assert.isTrue(subIt.hasNext());
		Assert.equals(3, subIt.next());
		Assert.equals(3, subIt.next());
		Assert.equals(3, subIt.next());
		Assert.isFalse(subIt.hasNext());
		
		Assert.isFalse(it.hasNext());
		
	}
	
	function nestedReturnedValue (data:Data):Iterator<Dynamic> {
		
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
		
		Assert.isTrue(it.hasNext());
		var funcGetFirst = it.next();
		Assert.isTrue(Reflect.isFunction(funcGetFirst));
		var firstSubIt = funcGetFirst();
		Assert.isFalse(it.hasNext());
		
		Assert.isTrue(firstSubIt.hasNext());
		var funcGetSecond = firstSubIt.next();
		Assert.isTrue(Reflect.isFunction(funcGetSecond));
		var secondSubIt:Iterator<Dynamic> = funcGetSecond();
		Assert.isFalse(firstSubIt.hasNext());
		
		Assert.isTrue(secondSubIt.hasNext());
		Assert.equals(3, secondSubIt.next());
		Assert.equals(4, secondSubIt.next());
		Assert.equals("two", secondSubIt.next());
		Assert.isFalse(secondSubIt.hasNext());
		
	}
	
	function nestedReturnedValue2 (data:Data, data2:Data):Iterator<Dynamic> {
		
		@yield return switch (data) {
			case Data.None: 10;
			case Data.WrappedMessages(_.get() => s, _.get() => v): 
				
				function ():Iterator<Dynamic> {
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
		
		Assert.isTrue(it.hasNext());
		Assert.equals("foo", it.next());
		Assert.equals("foo", it.next());
		Assert.equals("foofoo", it.next());
		Assert.isFalse(it.hasNext());
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
	
	function testInitialization () {
		var it = initialization();
		Assert.isTrue(it.hasNext());
		Assert.equals(2, it.next());
		Assert.equals(3, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function initialization () {
		
		var v:Int;
		
		switch (2) {
			case 0: v = 0;
			case 1: throw null;
			case 2: v = 2;
			default: v = 3;
		}
		
		@yield return v;
		
		var v:Int;
		
		switch (4) {
			case 0: v = 0;
			case 1: throw null;
			case 2: v = 2;
			case _: v = 3;
		}
		
		@yield return v;
	}

	function testLocalEnum () {
		var it = localEnum(ValueEnum.Value1);
		Assert.equals(1, it.next());
		Assert.equals(-2, it.next());
		Assert.equals(-3, it.next());
		Assert.equals(-4, it.next());
		Assert.equals(10, it.next());
		Assert.equals(100, it.next());
		var it = localEnum(ValueEnum._Value2);
		Assert.equals(-1, it.next());
		Assert.equals(2, it.next());
		Assert.equals(-3, it.next());
		Assert.equals(-4, it.next());
		Assert.equals(20, it.next());
		Assert.equals(200, it.next());
		var it = localEnum(ValueEnum.value3);
		Assert.equals(-1, it.next());
		Assert.equals(-2, it.next());
		Assert.equals(3, it.next());
		Assert.equals(-4, it.next());
		Assert.equals(30, it.next());
		Assert.equals(300, it.next());
		var it = localEnum(ValueEnum._value4);
		Assert.equals(-1, it.next());
		Assert.equals(-2, it.next());
		Assert.equals(-3, it.next());
		Assert.equals(4, it.next());
		Assert.equals(40, it.next());
		Assert.equals(400, it.next());
		var it = localEnum(ValueEnum.None);
		Assert.equals(-1, it.next());
		Assert.equals(-2, it.next());
		Assert.equals(-3, it.next());
		Assert.equals(-4, it.next());
		Assert.equals(0, it.next());
		Assert.equals(0, it.next());
	}

	function localEnum (value:ValueEnum):Iterator<Int> {
		
		if (value == Value1) {
			@yield return 1;
		} else {
			@yield return -1;
		}

		if (value == _Value2) {
			@yield return 2;
		} else {
			@yield return -2;
		}

		if (value == value3) {
			@yield return 3;
		} else {
			@yield return -3;
		}

		if (value == _value4) {
			@yield return 4;
		} else {
			@yield return -4;
		}

		var result:Int = switch (value) {
			case Value1: 10;
			case _Value2: 20;
			case value3: 30;
			case _value4: 40;
			case _: 0;
		};
		@yield return result;

		switch (value) {
			case Value1: @yield return 100;
			case _Value2: @yield return 200;
			case value3: @yield return 300;
			case _value4: @yield return 400;
			case _: @yield return 0;
		}
	}
	
	function testImportedEnum () {
		var it = importedEnum(B);
		Assert.equals(1, it.next());
		var it = importedEnum(BB);
		Assert.equals(2, it.next());
		var it = importedEnum(BBB);
		Assert.equals(3, it.next());
	}

	function importedEnum (value:EnumB):Iterator<Int> {
		
		switch (value) {
			case EnumB.B: @yield return 1;
			case BB: @yield return 2;
			case _: @yield return 3;
		}
	}
	
	// function testImportedAllEnum () { // TODO
	// 	var it = importedAllEnum(A);
	// 	Assert.equals(1, it.next());
	// 	var it = importedAllEnum(AA);
	// 	Assert.equals(2, it.next());
	// 	var it = importedAllEnum(AAA);
	// 	Assert.equals(3, it.next());
	// }

	// function importedAllEnum (value:EnumA):Iterator<Int> {
		
	// 	switch (value) {
	// 		case EnumA.A: @yield return 1;
	// 		case AA: @yield return 2;
	// 		case _: @yield return 3;
	// 	}
	// }
}

enum Data {
	None;
	Message(msg:String);
	WrappedMessage(msg:Getter<String>);
	Messages(msg1:String, msg2:Int);
	WrappedMessages(msg1:Getter<String>, msg2:Getter<Int>);
}

enum ValueEnum {
	Value1;
	_Value2;
	value3;
	_value4;
	None;
}

typedef Getter<T> = {
	function get (): T;
}