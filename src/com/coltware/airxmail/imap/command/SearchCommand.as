/**
 *  Copyright (c)  2009 coltware.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxmail.imap.command
{
	import com.coltware.airxmail.imap.IMAP4ListEvent;
	import com.coltware.commons.utils.StringLineReader;
	
	import mx.utils.StringUtil;

	public class SearchCommand extends IMAP4Command
	{
		private var _useUid:Boolean = false;
		
		/**
		 *   useUid: true ( UID SEARCH )
		 */
		public function SearchCommand(args:String,useUid:Boolean = true)
		{
			super();
			if(useUid){
				this.key = "UID SEARCH";
			}
			else{
				this.key = "SEARCH";
			}
			_useUid = useUid;
			this.value = args;
		}
		
		override protected function parseResult(reader:StringLineReader):void{
			var line:String;
			while(line = reader.next()){
				var pos:int = line.indexOf("SEARCH");
				if(pos > 0){
					var value:String = line.substr(pos + "SEARCH".length);
					value = StringUtil.trim(value);
					var reg:RegExp = /\s+/;
					var list:Array = value.split(reg);
					var event:IMAP4ListEvent;
					if(_useUid){
						event = new IMAP4ListEvent(IMAP4ListEvent.IMAP4_RESULT_UID_LIST);
					}
					else{
						event = new IMAP4ListEvent(IMAP4ListEvent.IMAP4_RESULT_LIST);
					}
					event.result = list;
					client.dispatchEvent(event);
				}
			}
		}
	}
}