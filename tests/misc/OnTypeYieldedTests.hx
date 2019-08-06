package misc;

import utest.Assert;
import pack.pack2.MiscYielded;

class SimpleModificationType {
	public function new () {}
}

class ReparsingType {
	public function new () {}
}

@:yield
class OnTypeYieldedTests extends utest.Test {

    function testSimpleModification () {
		var it:Iterator<Dynamic> = simpleModification();
		Assert.equals(null, it.next());
	}
	function simpleModification () {
		@yield return new SimpleModificationType();
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

}