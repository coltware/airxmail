/**
 *  Copyright (c)  2009 coltware.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxmail.imap.utils
{
	import flash.utils.ByteArray;
	
	import mx.logging.ILogger;
	import mx.logging.Log;

	public class IMAPUTF7Encoder
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxmail.imap.utils.IMAPUTF7Encoder");
		
		public function IMAPUTF7Encoder()
		{
		}
		
		public function encode(value:String):String{
			
			var bytes:ByteArray = new ByteArray();
			for(var i:int=0; i<value.length; i++){
				
			}
			//
			//  TODO dummy code
			//
			return value;
		}
		
		private static const keymap:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+,";
	}
}