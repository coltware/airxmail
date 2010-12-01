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
	import com.coltware.airxlib.job.SocketJobSync;
	import com.coltware.airxlib.utils.StringLineReader;
	import com.coltware.airxmail.MailParser;
	import com.coltware.airxmail.TextSocketReader;
	import com.coltware.airxmail.TextSocketReaderEvent;
	import com.coltware.airxmail.imap.chain.ISearch;
	import com.coltware.airxmail.imap.chain.ISelect;
	import com.coltware.airxmail.imap.command.CapabilityCommand;
	import com.coltware.airxmail.imap.command.CreateCommand;
	import com.coltware.airxmail.imap.command.DeleteCommand;
	import com.coltware.airxmail.imap.command.ExamineCommand;
	import com.coltware.airxmail.imap.command.IMAP4Command;
	import com.coltware.airxmail.imap.command.IdleCommand;
	import com.coltware.airxmail.imap.command.ListCommand;
	import com.coltware.airxmail.imap.command.LoginCommand;
	import com.coltware.airxmail.imap.command.LogoutCommand;
	import com.coltware.airxmail.imap.command.LsubCommand;
	import com.coltware.airxmail.imap.command.MessageCommand;
	import com.coltware.airxmail.imap.command.NamespaceCommand;
	import com.coltware.airxmail.imap.command.NoopCommand;
	import com.coltware.airxmail.imap.command.RenameCommand;
	import com.coltware.airxmail.imap.command.SearchCommand;
	import com.coltware.airxmail.imap.command.SelectCommand;
	import com.coltware.airxmail.imap.command.StoreCommand;
	import com.coltware.airxmail_internal;
	
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.setTimeout;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.StringUtil;
	
	use namespace airxmail_internal;
	
	[Event(name="jobStackEmpty",type="com.coltware.airxlib.job.JobEvent")]
	[Event(name="jobIdleTimeout",type="com.coltware.airxlib.job.JobEvent")]
	
	[Event(name="imap4ResultUidList",type="com.coltware.airxmail.imap.IMAP4ListEvent")]
	[Event(name="imap4ResultList",type="com.coltware.airxmail.imap.IMAP4ListEvent")]
	
	[Event(name="imap4CommandOk",type="com.coltware.airxmail.imap.IMAP4Event")]
	[Event(name="imap4CommandNo",type="com.coltware.airxmail.imap.IMAP4Event")]
	[Event(name="imap4CommandBad",type="com.coltware.airxmail.imap.IMAP4Event")]
	
	[Event(name="imap4FolderResult",type="com.coltware.airxmail.imap.IMAP4Event")]
	/**
	 *  @eventType com.coltware.airxmail.imap.IMAP4MessageEvent.IMAP4_MESSAGE
	 */
	[Event(name="imap4Message",type="com.coltware.airxmail.imap.IMAP4MessageEvent")]
	
	
	
	public class IMAP4Client extends SocketJobSync
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxmail.imap.IMAP4Client");
		private static const _log:ILogger = Log.getLogger("com.coltware.airxmail_internal.IMAP4");
		
		private var _tag_prefix:String = "AX";
		
		/**
		 * Tag of command
		 */
		private var _tag_num:Number = 1000;
		
		private var _lineReader:StringLineReader;
		private var _resultReader:StringLineReader;
		
		private var _socketReader:TextSocketReader;
		
		private var _bytes:ByteArray;
		private var _parser:MailParser;
		
		private var _timeout_msec:int = 5000;
		private var _timeout_uint:uint = 0;
		
		private var _username:String;
		private var _password:String;
		
		private var _capabilityCmd:CapabilityCommand;
		
		private var _isIdle:Boolean = false;
		private var _isIdleDone:Boolean = false;
		
		public function IMAP4Client(target:IEventDispatcher=null)
		{
			super(target);
			_lineReader = new StringLineReader();
			_resultReader = new StringLineReader();
			_parser = new MailParser();
			
			this.port = 143;
			
			_socketReader = new TextSocketReader();
			_socketReader.addEventListener(TextSocketReaderEvent.TEXT_SOCKET_LINE, handleLine);
		}
		
		public function setAuth(user:String,pswd:String):void{
			log.debug("set auth : " + user);
			this._username = user;
			this._password = pswd;
		}
		
		override public function connect():void{
			this.clearJobs();
			this._tag_num = 1000;
			super.connect();
			
			this.capability();
			
		}
		
		/**
		 *  Do capability command
		 */
		public function capability():void{
			var job:IMAP4Command = new CapabilityCommand();
			this.addJob(job);
		}
		
		public function login():void{
			var job:LoginCommand = new LoginCommand(this._username,this._password);
			this.addJob(job);
		}
		
		public function logout():void{
			var job:LogoutCommand = new LogoutCommand();
			this.addJob(job);
		}
		
		public function noop(tag:String = null):void{
			var job:NoopCommand = new NoopCommand();
			if(tag){
				job.tag = tag;
			}
			this.addJob(job);
		}
		
		public function idle():void{
			var job:IdleCommand = new IdleCommand();
			this.addJob(job);
		}
		
		public function list(base:String = "",mailbox:String = "*"):void{
			var job:ListCommand = new ListCommand(base,mailbox);
			this.addJob(job);
		}
		
		public function listBlocking(base:String = "",mailbox:String = "*"):void{
			var job:ListCommand = new ListCommand(base,mailbox);
			job.block(true);
			this.addJob(job);
		}
		
		public function lsub(base:String = "",mailbox:String = "*"):void{
			var job:LsubCommand = new LsubCommand(base,mailbox);
			this.addJob(job);
		}
		
		public function lsubBlocking(base:String = "",mailbox:String = "*"):void{
			var job:LsubCommand = new LsubCommand(base,mailbox);
			job.block(true);
			this.addJob(job);
		}
		
		public function selectMailbox(folder:Object):ISearch{
			var job:SelectCommand = new SelectCommand(folder);
			this.addJob(job);
			return job;
		}
		
		public function examineMailbox(folder:Object):ISearch{
			var job:ExamineCommand = new ExamineCommand(folder);
			this.addJob(job);
			return job;
		}
		
		public function search(args:String,useUid:Boolean = true):void{
			var job:SearchCommand = new SearchCommand(args,useUid);
			this.addJob(job);
		}
		
		public function message(msgId:String,useUid:Boolean = true):void{
			var job:MessageCommand = new MessageCommand(msgId,useUid);
			this.addJob(job);
		}
		
		public function createMailbox(mailbox:String):void{
			var job:CreateCommand = new CreateCommand(mailbox);
			this.addJob(job);
		}
		
		public function deleteMailbox(mailbox:String):void{
			var job:DeleteCommand = new DeleteCommand(mailbox);
			this.addJob(job);
		}
		
		public function renameMailbox(oldmailbox:String,newmailbox:String):void{
			var job:RenameCommand = new RenameCommand(oldmailbox,newmailbox);
			this.addJob(job);
		}
		
		public function addFlags(msgid:String,flags:Array,useUid:Boolean = true):void{
			var job:StoreCommand = new StoreCommand(StoreCommand.ADD,msgid,flags,useUid);
			this.addJob(job);
		}
		
		public function removeFlags(msgid:String,flags:Array,useUid:Boolean = true):void{
			var job:StoreCommand = new StoreCommand(StoreCommand.REMOVE,msgid,flags,useUid);
			this.addJob(job);
		}
		
		override protected function addJob(job:Object):void{
			var imap4cmd:IMAP4Command = job as IMAP4Command;
			imap4cmd.client = this;
			super.addJob(imap4cmd);
		}
		
		override protected function exec(job:Object):void{
			
			var imap4cmd:IMAP4Command = job as IMAP4Command;
			
			var tagname:String;
			if(imap4cmd.tag){
				tagname = imap4cmd.tag;
			}
			else{
				tagname = _tag_prefix + (String(this._tag_num));
			}
			var cmd:String = imap4cmd.createCommand(tagname,this._capabilityCmd);
			
			if(this._sock.connected){
				this._tag_num++;
				this._sock.writeUTFBytes(cmd + "\r\n");
				this._sock.flush();
				
				_log.debug("CMD[" + cmd + "]");
				
				if(imap4cmd is IdleCommand){
					this._isIdle = true;
					this._isIdleDone = false;
				}
				
			}
			else{
				var evt:IOErrorEvent = new IOErrorEvent(IOErrorEvent.IO_ERROR);
				this.dispatchEvent(evt);
			}
		}
		
		override protected function handleData(pe:ProgressEvent):void{
			_socketReader.parse(IDataInput(_sock));
		}
		
		protected function handleLine(lineEvt:TextSocketReaderEvent):void{
			var bytes:ByteArray = lineEvt.lineBytes;
			
			bytes.position = 0;		
			
			if(this.isServiceReady){
				
				if(this.currentJob ){
					var job:IMAP4Command = this.currentJob as IMAP4Command;
					var line:String = bytes.readUTFBytes(bytes.bytesAvailable);
					
					if(this.currentJob is IdleCommand && this._isIdleDone == false){
						
						if(this._isIdle){
							line = StringUtil.trim(line);
							if(line.substr(0,1) == "*"){
								//  "*" を含む何らかの返事が返ってきた
								this._isIdle = false;
								//  何をもって一連のレスポンスが終わっていると見なすかが不明・・・なので、
								//  1.5秒後にDONEを送る。特にその根拠はないが、そのくらい待てば大丈夫だと思うから
								setTimeout(_commitIdleJob,1500);
							}
						}
					}
					else{
					
						var tag:String = job.tag;
						var tlen:int = tag.length;
	
						if(line.substr(0,tlen) == tag){
							//_log.debug("[" + tag + "]>" + StringUtil.trim(line));
							// Status Line
							var reg:RegExp = /\s+/;
							var arr:Array = line.split(reg);
							
							if(arr.length > 1){
								var status:String = arr[1];
								job.status = status;
								if(status == "OK"){
									var result:ByteArray = new ByteArray();
									_socketReader.resultBytes.readBytes(result,0,_socketReader.resultBytes.bytesAvailable);
									result.position = 0;
									job.$result_parse(result);
									if(job is CapabilityCommand){
										this._capabilityCmd = job as CapabilityCommand;
									}
									else if(job is LoginCommand){
										if(this._capabilityCmd && this._capabilityCmd.has("NAMESPACE")){
											var njob:NamespaceCommand = new NamespaceCommand();
											this.addJobAt(njob,0);
										}
									}
									var eventOk:IMAP4Event = new IMAP4Event(IMAP4Event.IMAP4_COMMAND_OK);
									eventOk.$command = job;
									eventOk.$message = StringUtil.trim(line.substr(line.indexOf("OK") + "OK".length));
									
									this.dispatchEvent(eventOk);
									_socketReader.clear();
									
									this.commitJob();
								}
								else if(status == "NO"){
									var eventNo:IMAP4Event = new IMAP4Event(IMAP4Event.IMAP4_COMMAND_NO);
									eventNo.$message = StringUtil.trim(line.substr(line.indexOf("NO") + "NO".length));
									
									this.dispatchEvent(eventNo);
									_socketReader.clear();
								}
								else if(status == "BAD"){
									var eventBad:IMAP4Event = new IMAP4Event(IMAP4Event.IMAP4_COMMAND_BAD);
									eventBad.$message = StringUtil.trim(line.substr(line.indexOf("BAD") + "BAD".length));
									
									this.dispatchEvent(eventBad);
									_socketReader.clear();
								}
							}
						}
					}
				}
				else{
					// TODO Error handle
				}
			}
			else{
				this.handleNotServiceReady(bytes);
			}
		}
		
		
		/**
		 * サービスがまだ準備できていない時の処理
		 */
		private function handleNotServiceReady(lineBytes:ByteArray):void{
			lineBytes.position = 0;
			var line:String = StringUtil.trim(lineBytes.readUTFBytes(lineBytes.bytesAvailable));
			if(line.substr(0,4) == "* OK"){
				_socketReader.clear();
				this.serviceReady();
			}
			var e:IMAP4Event;
			if(this.isServiceReady){
				e = new IMAP4Event(IMAP4Event.IMAP4_CONNECT_OK);
			}
			else{
				e = new IMAP4Event(IMAP4Event.IMAP4_CONNECT_NG);
				e.$message = line;
			}
			e.client = this;
			this.dispatchEvent(e);
		}
		
		/**
		 *  IDLEコマンドで何らかの結果が帰ってきたときの処理
		 * 
		 */
		private function _commitIdleJob():void{
			log.debug("_commitIdleJob");
			this._sock.writeUTFBytes("DONE\r\n");
			this._sock.flush();
			this._isIdleDone = true;
		}
	}
}