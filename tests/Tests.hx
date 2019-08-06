package;
import utest.Runner;
import utest.ui.Report;
import utest.ui.common.HeaderDisplayMode;
import misc.InferenceTests;
import misc.AccessionTests;
import eparsers.ESwitchTests;
import misc.ImportTests;
import misc.IterationTests;
import misc.AbstractTests;
import misc.PrivateTests;
import misc.ScopeTests;
import misc.UsingTests;
import misc.YieldTests;
import misc.InheritanceTests;
import misc.OnTypeYieldedTests;
import eparsers.EForTests;
import eparsers.EFunctionTests;
import eparsers.ETryTests;
import eparsers.EWhileTests;
import eparsers.EIfTests;
import options.ExplicitTests;
import options.ExtendTests;
import options.KeywordTests;
import options.parsing.ParsingTests;
import options.parsing.subparsing.SubParsingTests;
import options.parsing.subparsing.unparsed.UnparsedTests;
import options.parsing.recursive.RecursiveParsingTests;
import options.parsing.recursive.parsed.RecursiveSubParsingTests;

class Tests
{
	static function main () {
		
		var r:Runner = new Runner();
		
		// parsers
		r.addCase(new EIfTests());
		r.addCase(new EWhileTests());
		r.addCase(new EForTests());
		r.addCase(new ETryTests());
		r.addCase(new EFunctionTests());
		r.addCase(new ESwitchTests());
		
		// general tests
		r.addCase(new ScopeTests());
		r.addCase(new ImportTests());
		r.addCase(new UsingTests());
		r.addCase(new YieldTests());
		r.addCase(new IterationTests());
		r.addCase(new AbstractTests());
		r.addCase(new AccessionTests());
		r.addCase(new InferenceTests());
		r.addCase(new InheritanceTests());
		r.addCase(new PrivateTests());
		r.addCase(new OnTypeYieldedTests());
		
		// options tests
		r.addCase(new ExtendTests());
		r.addCase(new KeywordTests());
		r.addCase(new ExplicitTests());
		r.addCase(new ParsingTests());
		r.addCase(new SubParsingTests());
		r.addCase(new UnparsedTests());
		r.addCase(new RecursiveParsingTests());
		r.addCase(new RecursiveSubParsingTests());
		
		Report.create(r);

		r.run();
	}
	
}