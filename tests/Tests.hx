package;
import utest.Runner;
import utest.ui.Report;
import utest.ui.common.HeaderDisplayMode;

class Tests
{
	static function main () {
		
		var r:Runner = new Runner();
		
		// parsers
		r.addCase(new eparsers.EIfTests());
		r.addCase(new eparsers.EWhileTests());
		r.addCase(new eparsers.EForTests());
		r.addCase(new eparsers.ETryTests());
		r.addCase(new eparsers.EFunctionTests());
		r.addCase(new eparsers.ESwitchTests());
		
		// general tests
		r.addCase(new misc.ScopeTests());
		r.addCase(new misc.ImportTests());
		r.addCase(new misc.UsingTests());
		r.addCase(new misc.YieldTests());
		r.addCase(new misc.IterationTests());
		r.addCase(new misc.AbstractTests());
		r.addCase(new misc.GenericTests());
		r.addCase(new misc.AccessionTests());
		r.addCase(new misc.InferenceTests());
		r.addCase(new misc.InheritanceTests());
		r.addCase(new misc.PrivateTests());
		r.addCase(new misc.OnTypeYieldedTests());
		
		// options tests
		r.addCase(new options.ExtendTests());
		r.addCase(new options.KeywordTests());
		r.addCase(new options.ExplicitTests());
		r.addCase(new options.parsing.ParsingTests());
		r.addCase(new options.parsing.subparsing.SubParsingTests());
		r.addCase(new options.parsing.subparsing.unparsed.UnparsedTests());
		r.addCase(new options.parsing.recursive.RecursiveParsingTests());
		r.addCase(new options.parsing.recursive.parsed.RecursiveSubParsingTests());
		
		Report.create(r);

		r.run();
	}
	
}