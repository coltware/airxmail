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
	import com.coltware.airxmail.MailParser;
	import com.coltware.airxmail.imap.command.CapabilityCommand;
	import com.coltware.airxmail.imap.command.CreateCommand;
	import com.coltware.airxmail.imap.command.DeleteCommand;
	import com.coltware.airxmail.imap.command.IMAP4Command;
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
	import com.coltware.airxmail_internal;
	import com.coltware.commons.job.SocketJobSync;
	import com.coltware.commons.utils.StringLineReader;
	
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.StringUtil;
	
	use namespace airxmail_internal;
	
	[Event(name="jobStackEmpty",type="com.coltware.commons.job.JobEvent")]
	[Event(name="jobIdleTimeout",type="com.coltware.commons.job.JobEvent")]
	
	[Event(name="imap4ResultUidList",type="com.coltware.airxmail.imap.IMAP4ListEvent")]
	[Event(name="imap4ResultList",type="com.coltware.airxmail.imap.IMAP4ListEvent")]
	
	/**
	 *  @eventType com.coltware.airxmail.imap.IMAP4MessageEvent.IMAP4_MESSAGE
	 */
	[Event(name="imap4Message",type="com.coltware.airxmail.imap.IMAP4MessageEvent")]
	
	public class IMAP4Client extends SocketJobSync
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxmail.imap.IMAP4Client");
		
		/**
		 * Tag of command
		 */
		private var _tag_num:Number = 1000;
		
		private var _lineReader:StringLineReader;
		private var _resultReader:StringLineReader;
		private var _bytes:ByteArray;
		private var _parser:MailParser;
		
		private var _timeout_msec:int = 5000;
		private var _timeout_uint:uint = 0;
		
		private var _username:String;
		private var _password:String;
		
		private var _capabilityCmd:CapabilityCommand;
		
		public function IMAP4Client(target:IEventDispatcher=null)
		{
			super(target);
			_lineReader = new StringLineReader();
			_resultReader = new StringLineReader();
			_parser = new MailParser();
			
			this.port = 143;
			
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
		
		public function noop():void{
			var job:NoopCommand = new NoopCommand();
			this.addJob(job);
		}
		
		public function list(base:String = "",mailbox:String = "*"):void{
			var job:ListCommand = new ListCommand(base,mailbox);
			this.addJob(job);
		}
		
		public function lsub(base:String = "",mailbox:String = "*"):void{
			var job:LsubCommand = new LsubCommand(base,mailbox);
			this.addJob(job);
		}
		
		public function select(mailbox:String):void{
			var job:SelectCommand = new SelectCommand(mailbox);
			this.addJob(job);
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
		
		override protected function exec(job:Object):void{
			
			var imap4cmd:IMAP4Command = job as IMAP4Command;
			imap4cmd.client = this;
			
			var cmd:String = imap4cmd.createCommand(String(this._tag_num),this._capabilityCmd);
			
			if(this._sock.connected){
				this._tag_num++;
				this._sock.writeUTFBytes(cmd + "\r\n");
				this._sock.flush();
				
				log.debug("write imap4 cmd [" + cmd + "]");
			}
			else{
				var evt:IOErrorEvent = new IOErrorEvent(IOErrorEvent.IO_ERROR);
				this.dispatchEvent(evt);
			}
		}
		
		override protected function handleData(pe:ProgressEvent):void{
			
			var buf:ByteArray;
			
			if(this.isServiceReady){
				if(this.currentJob){
					var job:IMAP4Command = this.currentJob as IMAP4Command;
					var tag:String = job.tag;
					var tlen:int = tag.length;
					var line:String;
				
					_lineReader.source = IDataInput(_sock);
					while(line = _lineReader.next()){
						
						if(!job is MessageCommand){
							log.debug("[" + tag + "]>" + line);
						}
						
						if(line.substr(0,tlen) == tag){
							//  Status line
							var reg:RegExp = /\s+/;
							var arr:Array = line.split(reg);
							if(arr.length > 1){
								var status:String = arr[1];
								job.status = status;
								if(status == "OK"){
									job.$result_parse();
								
									if(job is CapabilityCommand){
										this._capabilityCmd = job as CapabilityCommand;
									}
									else if(job is LoginCommand){
										if(this._capabilityCmd && this._capabilityCmd.has("NAMESPACE")){
											var njob:NamespaceCommand = new NamespaceCommand();
											this.addJobAt(njob,0);
										}
									}
									this.commitJob();
								}
								else if(status == "NO"){
									var eventNo:IMAP4Event = new IMAP4Event(IMAP4Event.IMAP4_COMMAND_NO);
									eventNo.$message = StringUtil.trim(line.substr(line.indexOf("NO") + "NO".length));
									this.dispatchEvent(eventNo);
								}
								else if(status == "BAD"){
									var eventBad:IMAP4Event = new IMAP4Event(IMAP4Event.IMAP4_COMMAND_BAD);
									eventBad.$message = StringUtil.trim(line.substr(line.indexOf("BAD") + "BAD".length));
									this.dispatchEvent(eventBad);
								}
								
							}
							else{
								// @TODO Error handler
							}
							
						}
						else{
							job.resultBytes.writeBytes(_lineReader.lastBytearray());
						}
						
					}
				}
				else{
					// @TODO Handle Error
					log.warn("null command error...");
				}
				
			}
			else{
				this.handleNotServiceReady(pe);
			}
		}
		/**
		 * サービスがまだ準備できていない時の処理
		 */
		private function handleNotServiceReady(pe:ProgressEvent):void{
			var line:String;
			_lineReader.source = IDataInput(_sock);
			while(line = _lineReader.next()){
					line = StringUtil.trim(line);
					if(line.substr(0,4) == "* OK"){
						this.serviceReady();
						break;
					}
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
		
		
	}
}