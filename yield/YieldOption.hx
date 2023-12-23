/*
 * The MIT License
 * 
 * Copyright (C)2023 Dimitri Pomier
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
package yield;

#if !macro
extern
#end
enum YieldOption {
	
	/**
	 * Use a custom keyword instead of "yield".
	 */
	Keyword(s:String);
	
	/**
	 * If the option is enabled, the return type of iterative functions
	 * needs to be explicitly specified. This is disabled by default.
	 */
	Explicit(?v:Bool);
	
	/**
	 * If the option is enabled, all extending classes will be able
	 * to use yield statements. If this option affects an interface,
	 * all implementing classes and all extending interfaces will
	 * be able to use yield statements. This is disabled by default.
	 */
	Extend(?v:Bool);
}