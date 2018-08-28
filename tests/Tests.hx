package;
import utest.Runner;
import utest.ui.Report;
import utest.Assertation;
import utest.TestHandler;
import utest.TestFixture;
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
import eparsers.EForTests;
import eparsers.EFunctionTests;
import eparsers.ETryTests;
import eparsers.EWhileTests;
import eparsers.EIfTests;
import options.ExplicitTests;
import options.ExtendTests;
import options.KeywordTests;

class Tests
{
	static var success:Bool = true;

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
		
		// options tests
		r.addCase(new ExtendTests());
		r.addCase(new KeywordTests());
		r.addCase(new ExplicitTests());
		
		r.onTestComplete.add(onTestComplete);
		r.onComplete.add(onComplete);

		#if travix
		r.onTestComplete.add(onTestComplete);
		r.onComplete.add(onComplete);
		#else
		Report.create(r);
		#end

		r.run();
	}

	static function onTestComplete (test:TestHandler<TestFixture>) {

		for (assertation in test.results) {
		
			switch (assertation) {
				case Success(_) | Ignore(_):
				case _: 
					success = false;
					break;
			}
		}
	}

	static function onComplete (r:Runner):Void {

		if (success) {
			
			#if travix
			travix.Logger.exit(0);
			#end
		}
	}
	
}