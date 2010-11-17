/**
 *  Copyright (c)  2009 coltware.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxmail.imap
{
	import mx.logging.ILogger;
	import mx.logging.Log;

	public class IMAP4Folder
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxmail.imap.IMAP4Folder");
		
		private var _name:String;
		private var _delim:String;
		
		public function IMAP4Folder(name:String,delim:String)
		{
			this._name = name;
			this._delim = delim;
		}
	}
}