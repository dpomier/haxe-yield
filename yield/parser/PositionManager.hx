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
	
	private var m_ibd:IteratorBlockData;
	private var m_posPointers:Array<Array<LinkedPosition>>;

	public function new (iteratorBlocks:IteratorBlockData) {
		
		m_ibd = iteratorBlocks;
		m_posPointers = new Array<Array<LinkedPosition>>();
	}
	
	public function addPosPointer (lp:LinkedPosition): Void {
		
		if (m_posPointers.length <= lp.pos || m_posPointers[lp.pos] == null) {
			m_posPointers[lp.pos] = new Array<LinkedPosition>();
		}
		
		m_posPointers[lp.pos].push(lp);
	}
	
	public function moveLinkedPosition (lp:LinkedPosition, newPos:Int): Void {
		
		m_posPointers[lp.pos].remove(lp);
		
		if (newPos >= 0) {
			lp.pos = newPos;
			addPosPointer(lp);
		}
	}
	
	public function adjustIteratorPos (offset:Int, since:Int): Void {
		
		var ibdLength:Int = m_ibd.length;
		var posCount:Int  = m_posPointers.length;
		
		for (i in since...ibdLength + 1) {
			
			if (i < posCount && m_posPointers[i] != null) {
				
				for (posPtr in m_posPointers[i]) {
					
					posPtr.pos += offset;
				}
			}
		}
		
		for (i in since...ibdLength + 1) {
			
			if (i < posCount && m_posPointers[i] != null) {
				
				var j:Int = m_posPointers[i].length;
				
				while (--j != -1) {
					
					if (m_posPointers[i][j].pos >= 0) {
						addPosPointer(m_posPointers[i][j]);
					}
					
					m_posPointers[i].splice(j, 1);
				}
			}
		}
	}
	
}
#end