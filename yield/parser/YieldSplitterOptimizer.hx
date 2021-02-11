/*
 * The MIT License
 * 
 * Copyright (C)2021 Dimitri Pomier
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
#if (macro || display)
package yield.parser;
import haxe.macro.Expr.Position;
import yield.parser.env.WorkEnv;
import yield.parser.PositionManager.LinkedPosition;

class YieldSplitterOptimizer {
	
	public static function optimizeAll (ys:YieldSplitter, pm:PositionManager, env:WorkEnv, pos:Position): Void {
		
		#if (yield_debug_no_display || !display && !yield_debug_display)
		
		var pass:Int = 0;
		var subpass:Int = 0;
		var needRepass:Bool = true;
		
		while (needRepass && ++pass < 10) {
			
			needRepass = false;
			subpass = 0;

			while (removeUselessSetActions(ys, pm, env, pos) && ++subpass < 10)
				needRepass = true;
			while (removeSuperfluousSetActionCalls(ys, pm, env, pos) && ++subpass < 20)
				needRepass = true;
			while (removeSuperfluousGotoActionCalls(ys, pm, env, pos) && ++subpass < 30)
				needRepass = true;
		}

		#if yield_debug
		if (env.debug) {
			trace('"${env.functionName}" optimazed in $pass pass');
		}
		#end
		
		#end
	}

	public static function removeUselessSetActions (ys:YieldSplitter, pm:PositionManager, env:WorkEnv, pos:Position): Bool {
		
		var optimized:Bool = false;
		
		var setsToRemove:Array<LinkedPosition> = [];
		
		for (iteratorBlock in ys.iteratorBlocks) {
			
			var lastSetAction:LinkedPosition;
			
			for (lexpr in iteratorBlock) {
				
				var isActionExpr:Bool = false;
				
				for (lset in env.setActions) {
					if (lexpr == lset.e) {
						
						if (lastSetAction != null)
							setsToRemove.push( lset );
						lastSetAction = lset;
						
						isActionExpr = true;
						break;
					}
				}
				
				if (isActionExpr) continue;
				
				for (lgoto in env.gotoActions) {
					if (lexpr == lgoto.e) {
						if (lastSetAction != null) 
							setsToRemove.push( lastSetAction );
						break;
					}
				}
				
				break;
			}
			
			var i:Int = setsToRemove.length;
			while (--i != -1) {
				
				iteratorBlock.remove(setsToRemove[i].e);
				env.setActions.remove(setsToRemove[i]);
				
				setsToRemove.splice(i, 1);
				optimized = true;
			}
		}
		
		return optimized;
	}
	
	public static function removeSuperfluousSetActionCalls (ys:YieldSplitter, pm:PositionManager, env:WorkEnv, pos:Position): Bool {
		
		var optimized:Bool = false;
		
		for (aSet in env.setActions) {
			
			if (aSet.pos >= ys.iteratorBlocks.length) continue;
			
			for (lexpr in ys.iteratorBlocks[aSet.pos]) {
				
				var isAnotherExpr:Bool = true;
				
				for (lset in env.setActions) {
					if (lexpr == lset.e) {
						isAnotherExpr = false;
						break;
					}
				}
				if (!isAnotherExpr) continue;
				
				for (lgoto in env.gotoActions) {
					if (lexpr == lgoto.e) {
						
						pm.moveLinkedPosition(aSet, lgoto.pos);
						optimized = true;
						
						isAnotherExpr = false;
						break;
					}
				}
				
				if (isAnotherExpr) break;
			}
		}
		
		return optimized;
	}
	
	public static function removeSuperfluousGotoActionCalls (ys:YieldSplitter, pm:PositionManager, env:WorkEnv, pos:Position): Bool {
		
		var optimized:Bool = false;
		
		var uncrossedPositions:Array<Int> = [];
		
		for (aGoto in env.gotoActions) {
			
			if (aGoto.pos >= ys.iteratorBlocks.length) continue;
			
			for (lexpr in ys.iteratorBlocks[aGoto.pos]) {
				
				var isAnotherExpr:Bool = true;
				
				for (lgoto in env.gotoActions) {
					if (lexpr == lgoto.e && aGoto.pos != lgoto.pos) {
						
						if (uncrossedPositions.indexOf(aGoto.pos) == -1)
							uncrossedPositions.push(aGoto.pos);
						
						pm.moveLinkedPosition(aGoto, lgoto.pos);
						optimized = true;
						
						isAnotherExpr = false;
						break;
					}
				}
				
				if (isAnotherExpr) break;
			}
		}
		
		var i:Int = uncrossedPositions.length;
		
		uncrossedPositions.sort(function(a, b) {
			if (a < b) return -1;
			else if (b < a) return 1;
			else return 0;
		});
		
		while (--i != -1) {
			ys.spliceIteratorBlocks(uncrossedPositions[i], 1);
		}
		
		return optimized;
	}
	
}
#end