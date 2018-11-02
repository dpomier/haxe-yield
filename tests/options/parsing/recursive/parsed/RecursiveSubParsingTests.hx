package options.parsing.recursive.parsed;

import utest.Assert;

class RecursiveSubParsingTests extends utest.Test {

    function testParsing () {
		var it = simpleSplit();
		Assert.equals(1, it.next());
		Assert.equals(2, it.next());
		Assert.equals(4, it.next());
		Assert.isFalse(it.hasNext());
	}
	
	function simpleSplit (): Iterator<Int> {
		@yield return 1;
		@yield return 2;
		@yield return 4;
	}

}