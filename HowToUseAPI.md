Please see my blog..

http://flex.coltware.com/as3-flex-air/airxmail/

# Sender API #
## SMTP Level API ##
**Basic Usage Part1**
```
var smtpClient:SMTPClient = new SMTPClient();
smtpClient.host = "smtp.foo.com";
// Add Socket Level ErrorHandler
smtpClient.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
smtpClient.addEventListener(SecurityErrorEvent.SECURITY_ERROR,errorHandler);
// Add SMTP Level ErrorHandler
smtpClient.addEventListener(SMTPEvent.SMTP_CONNECTION_FAILED, errorHandler);
smtpClient.connect();
smtpClient.helo("localhost");
smtpClient.mailFrom(fromEmail);
smtpClient.rcptTo(toEmail);
	
var mailText:String = 
	"Subject: test\r\n" +
 	"\r\n" + 
 	"this is body";
	
smtpClient.data(mailText);
smtpClient.quit();
```

**Basic Usage Part2**
```
:
//smtpClient.data(mailText);
//  if smtp session is ready to accept data, call event listener
smtpClient.addEventListener(SMTPEvent.SMTP_ACCEPT_DATA,writeData);
smtpClient.dataAsync();
:

private function writeData(e:SMTPEvent):void{
	//  Warning !! e.getSocket() method return "smtpClient.socketObject" 
	var obj:Object = e.getSocket();
	
	var sock:Socket = obj as Socket;
	sock.writeUTFBytes("Subject: this is test\r\n");
	sock.writeUTFBytes("\r\n");
	sock.writeUTFBytes("this is data");			
	// *MUST* needs following steps
	sock.writeUTFBytes("\r\n.\r\n");
	sock.flush();
}
```

## Sender API ##

undocumented...

# Reciver(POP3) API #

undocumented...