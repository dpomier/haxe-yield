/*
 * The MIT License
 * 
 * Copyright (C)2017 Dimitri Pomier
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
#if macro
package yield.parser;
import haxe.macro.Expr;
import yield.parser.YieldSplitter.IteratorBlockData;

typedef LinkedPosition = {
	var pos:Int;
	var e:Expr;
}

class PositionManager
{
	
	private var ibd:IteratorBlockData;
	private var posPointers:Array<Array<LinkedPosition>>;

	public function new (iteratorBlocks:IteratorBlockData) {
		
		ibd = iteratorBlocks;
		posPointers	= new Array<Array<LinkedPosition>>();
	}
	
	public function addPosPointer (lp:LinkedPosition): Void {
		
		if (posPointers.length <= lp.pos || posPointers[lp.pos] == null) {
			posPointers[lp.pos] = new Array<LinkedPosition>();
		}
		
		posPointers[lp.pos].push(lp);
	}
	
	public function moveLinkedPosition (lp:LinkedPosition, newPos:Int): Void {
		
		posPointers[lp.pos].remove(lp);
		
		if (newPos >= 0) {
			lp.pos = newPos;
			addPosPointer(lp);
		}
	}
	
	public function adjustIteratorPos (offset:Int, since:Int): Void {
		
		var ibdLength:Int = ibd.length;
		var posCount:Int  = posPointers.length;
		
		for (i in since...ibdLength + 1) {
			
			if (i < posCount && posPointers[i] != null) {
				
				for (posPtr in posPointers[i]) {
					
					posPtr.pos += offset;
				}
			}
		}
		
		for (i in since...ibdLength + 1) {
			
			if (i < posCount && posPointers[i] != null) {
				
				var j:Int = posPointers[i].length;
				
				while (--j != -1) {
					
					if (posPointers[i][j].pos >= 0) {
						addPosPointer(posPointers[i][j]);
					}
					
					posPointers[i].splice(j, 1);
				}
			}
		}
	}
	
}
#end