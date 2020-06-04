package misc;

import utest.Assert;
import pack.pack2.MiscYielded;

class SimpleModificationType {
	public function new () {}
}

class ReparsingType {
	public function new () {}
}

class ReEntranceType {
	public function new () {}
}

class LoopType {
	public function new () {}
}

@:yield
class OnTypeYieldedTests extends utest.Test {

	function testSimpleModification () {
		var it:Iterator<Dynamic> = simpleModification();
		Assert.equals(3, it.next());
	}
	function simpleModification ():Iterator<SimpleModificationType> {
		@yield return null;
	}

	function testImplicitModification () {
		var it:Iterator<Dynamic> = implicitModification();
		Assert.equals(3, it.next());
	}
	function implicitModification () {
		@yield return new SimpleModificationType();
	}

	function testReentrance () {
		var it:Iterator<Dynamic> = reentrance();
		Assert.isTrue(it.hasNext());
		Assert.equals(3, it.next());
		Assert.isFalse(it.hasNext());
	}
	function reentrance ():Iterator<ReEntranceType> {
		@yield return null;
	}

	function testReparsing () {
		var it:Iterator<Dynamic> = reparsing();

		var generatedFun = it.next();
		var generatedIt = generatedFun();
		
		Assert.equals(1, generatedIt.next());
		Assert.equals(2, generatedIt.next());
	}
	function reparsing () {
		@yield return new ReparsingType();
	}

	// function testLooping () {
	// 	var it:Iterator<Dynamic> = loop();
	// 	Assert.isTrue(it.hasNext());
	// 	Assert.equals("done", it.next());
	// 	Assert.isFalse(it.hasNext());

	// 	var it:Iterator<Dynamic> = loopImplicit();
	// 	Assert.isTrue(it.hasNext());
	// 	Assert.equals("done", it.next());
	// 	Assert.isFalse(it.hasNext());
	// }
	// function loop ():Iterator<LoopType> {
	// 	@yield return new LoopType();
	// }
	// function loopImplicit () {
	// 	@yield return new LoopType();
	// }

}