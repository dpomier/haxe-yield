package options.parsing.subparsing.unparsed;

import utest.Assert;

class UnparsedTests extends utest.Test {

    function testUnparsed () {
		var value:Int = unparsed();
		Assert.equals(1, value);
	}
	
	function unparsed (): Int {
		@yield return 1;
	}

}