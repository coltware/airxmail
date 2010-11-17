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
	import com.coltware.commons.utils.StringLineReader;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.StringUtil;

	public class SelectCommand extends IMAP4Command
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxmail.imap.command.SelectCommand");
		
		private var _exists:Number = 0;
		private var _recent:Number = 0;
		private var _uidvalidity:String;
		
		public function SelectCommand(value:String = "")
		{
			super();
			this.key = "SELECT";
			this.value = value;
		}
		
		override protected function parseResult(reader:StringLineReader):void{
			var line:String;
			while(line = reader.next()){
				var pos:int = line.indexOf("*");
				line = line.substr(pos+1);
				
				this._parse_exists(line);
				this._parse_recent(line);
				this._parse_uidvalidity(line);
			}
			
			log.debug("exists :[" + this._exists + "]");
			log.debug("recent:[" + this._recent + "]");
			log.debug("uid:[" + this._uidvalidity + "]");
		}
		
		private function _parse_exists(line:String):Boolean{
			var pos2:int = line.indexOf("EXISTS");
			if(pos2 > -1){
				var numStr:String = line.substr(0,pos2);
				numStr = StringUtil.trim(numStr);
				_exists = parseInt(numStr);
				return true;
			}
			return false;
		}
		
		private function _parse_recent(line:String):Boolean{
			var pos:int = line.indexOf("RECENT");
			if(pos > -1){
				var numStr:String = line.substr(0,pos);
				numStr = StringUtil.trim(numStr);
				_recent = parseInt(numStr);
				return true;
			}
			return false;
		}
		
		private function _parse_uidvalidity(line:String):Boolean{
			var pos:int = line.indexOf("UIDVALIDITY");
			if(pos > -1){
				var idStr:String = line.substr(pos + "UIDVALIDITY".length);
				var pos2:int = idStr.indexOf("]");
				this._uidvalidity = StringUtil.trim(idStr.substr(0,pos2));
			}
			return false;
		}
	}
}