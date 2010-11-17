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
	import com.coltware.airxmail.imap.IMAP4Folder;
	import com.coltware.commons.utils.StringLineReader;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.StringUtil;

	public class ListCommand extends IMAP4Command
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxmail.imap.command.ListCommand");
		
		private var _basename:String;
		private var _mailbox:String;
		
		private var _folder:IMAP4Folder;
		
		public static const NOINFERORS:String 	= "\Noinferiors";
		public static const NOSELECT:String 		= "\Noselect";
		public static const MARKED:String 			= "\Marked";
		public static const UNMARKED:String 		= "\Unmarked";
		public static const HAS_CHILDREN:String = "\HasChildren";
		public static const HAS_NO_CHILDREN:String = "\HasNoChildren";
		
		public function ListCommand(basename:String = "",mailbox:String = "*")
		{
			super();
			this.key = "LIST";
			this._basename = basename;
			this._mailbox = mailbox;
		}
		
		override public function createCommand(tag:String,capability:CapabilityCommand = null):String{
			this.tag = tag;
			var cmd:String = tag + " " + key + " \"" + this._basename + "\" \"" + this._mailbox + "\"";
			return cmd;
		} 
		
		override protected function parseResult(reader:StringLineReader):void{
			var line:String;
			while(line = reader.next()){
				var pos:int = line.indexOf(this.key);
				if(pos > 0 ){
					var value:String = line.substr(pos + this.key.length);
					value = StringUtil.trim(value);
					this._parse_list_line(value);
				}
			}
		}
		
		private function _parse_list_line(line:String):void{
			var pos1:int = line.indexOf("(");
			var pos2:int = line.indexOf(")");
			if(pos1 > -1 && pos2 > pos1 ){
				var type:String = line.substr(pos1 + 1,pos2 - pos1 -1);
				log.debug("list type=>" + type);
				
				var rest:String = line.substr(pos2 + 1);
				log.debug("list rest=>" + rest);
				
				var ret:Array = this._parse_quato_value(rest);
				if(ret){
					var ret2:Array = this._parse_quato_value(ret[1]);
					log.debug("delim => [" + ret[0] + "]");
					log.debug("box =>[" + ret2[0] + "]");
				}
			}
		}
		/**
		 *   "." "INBOX" のような感じの文字列をパースする
		 */
		private function _parse_quato_value(value:String):Array{
			var pos1:int = value.indexOf('"');
			if(pos1 > -1){
				var pos2:int = value.indexOf('"',pos1+1);
				var str:String = value.substr(pos1 + 1,pos2 - pos1 -1);
				var rest:String = value.substr(pos2+1);
				var ret:Array = [str,rest];
				return ret;
			}
			return null;
		}
		
	}
}