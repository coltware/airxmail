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
	import com.coltware.airxlib.job.IBlockable;
	import com.coltware.airxlib.utils.StringLineReader;
	import com.coltware.airxmail.imap.IMAP4Event;
	import com.coltware.airxmail.imap.IMAP4Folder;
	import com.coltware.airxmail_internal;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	use namespace airxmail_internal;

	public class StatusCommand extends IMAP4Command implements IBlockable
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxmail.imap.command.StatusCommand");
		
		private var _folder:IMAP4Folder;
		
		private var _name:String;
		
		private var _messagesNum:int = 0;
		private var _recentNum:int = 0;
		private var _unseenNum:int = 0;
		
		private var _uidnext:String;
		private var _uidvalidity:String;
		
		public function StatusCommand(folder_StringOrIMAP4Folder:Object=null)
		{
			super();
			this.key = "STATUS";
			if(folder_StringOrIMAP4Folder is IMAP4Folder){
				_folder = folder_StringOrIMAP4Folder as IMAP4Folder;
				this.value =  (folder_StringOrIMAP4Folder as IMAP4Folder).name;
			}
			else{
				this.value = folder_StringOrIMAP4Folder as String;
				_folder = new IMAP4Folder();
				_folder.nameUTF8 = this.value;
			}
			this._name = this.value;
			this.value += " (MESSAGES RECENT UIDNEXT UIDVALIDITY UNSEEN)";
		}
		
		public function isBlock():Boolean{
			return true;
		}
		
		override protected function parseResult(reader:StringLineReader):void{
			var line:String;
			while(line = reader.next()){
				var pos:int = line.indexOf(this._name);
				if(pos > 0){
					pos = pos + this._folder.name.length;
					var line2:String = line.substring(pos);
					var s:int = line2.indexOf("(");
					var e:int = line2.lastIndexOf(")");
					log.debug("line2 : [" + line2.substring(s+1,e) + "]");
					var arr:Array = line2.substring(s+1,e).split(" ");
					for(var i:int = 0; i<arr.length; i = i + 2){
						var key:String = arr[i];
						var val:String = arr[i+1];
						if(key == "MESSAGES"){
							this._messagesNum = parseInt(val);
						}
						else if(key == "RECENT"){
							this._recentNum = parseInt(val);
						}
						else if(key == "UNSEEN"){
							this._unseenNum = parseInt(val);
						}
						else if(key == "UIDNEXT"){
							this._uidnext = val;
						}
						else if(key == "UIDVALIDITY"){
							this._uidvalidity = val;
						}
					}
				}
			}
			if(this._folder){
				this._folder.$numExists = this._messagesNum;
				this._folder.$numRecent = this._recentNum;
				this._folder.$uidnext   = this._uidnext;
				this._folder.$uidvalidity = this._uidvalidity;
				
				
				var event:IMAP4Event = new IMAP4Event(IMAP4Event.IMAP4_FOLDER_STATUS);
				event.$command = this;
				event.client = this.client;
				event.result = this._folder;
				client.dispatchEvent(event);
			}
			else{
				// error
				log.warn("no folder ???");
			}
		}
		
		private function debugDump():void{
			log.debug("======== " + this._folder.nameUTF8 + " ============");
			log.debug("messages    : [" + this._messagesNum + "]");
			log.debug("recent      : [" + this._recentNum   + "]");
			log.debug("unseen      : [" + this._unseenNum   + "]");
			log.debug("uidnext     : [" + this._uidnext     + "]");
			log.debug("uidvalidity : [" + this._uidvalidity + "]");
		}
	}
}