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
	import com.coltware.airxmail.MailParser;
	import com.coltware.airxmail.imap.IMAP4MessageEvent;
	import com.coltware.commons.utils.StringLineReader;
	
	import flash.utils.ByteArray;

	public class MessageCommand extends IMAP4Command
	{
		private var _msgid:String;
		
		public function MessageCommand(msgid:String,useUid:Boolean = true)
		{
			super();
			if(useUid){
				this.key = "UID FETCH";
			}
			else{
				this.key = "FETCH";
			}
			_msgid = msgid;
			value = msgid + " RFC822";
		}
		
		override protected function parseResult(reader:StringLineReader):void{
			var line:String = reader.next();
			var pos1:int = line.indexOf("{");
			var pos2:int = line.indexOf("}");
			var sizeStr:String = line.substr(pos1 + 1,pos2-pos1 -1);
			var size:Number = parseInt(sizeStr);
			
			var newReader:StringLineReader = reader.create(size);
			var parser:MailParser = new MailParser();
			parser.parseStart(this._msgid);
			while(line = newReader.next()){
				parser.parseLine(line,newReader);
			}
			var event:IMAP4MessageEvent = new IMAP4MessageEvent(IMAP4MessageEvent.IMAP4_MESSAGE);
			event.result = parser.parseEnd();
			event.source = reader.source as ByteArray;
			event.octets = size;
			client.dispatchEvent(event);
			
		}
	}
}