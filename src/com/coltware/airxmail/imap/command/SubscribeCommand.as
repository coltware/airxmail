package com.coltware.airxmail.imap.command
{
	import com.coltware.airxlib.utils.StringLineReader;
	import com.coltware.airxmail.imap.IMAP4Folder;
	
	import mx.logging.ILogger;
	import mx.logging.Log;

	public class SubscribeCommand extends IMAP4Command
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxmail.imap.command.SubscribeCommand");
		
		public function SubscribeCommand(folder:Object)
		{
			super();
			this.key 	= "SUBSCRIBE";
			if(folder is IMAP4Folder){
				this.value = IMAP4Folder(folder).name;
			}
			else{
				this.value = folder.toString();
			}
		}
		
		override protected function parseResult(reader:StringLineReader):void{
			var line:String;
			while(line = reader.next()){
				log.debug(line);
			}
		}
	}
}