EventEmitter = require('events').EventEmitter
Q = require 'q'
inbox = require 'inbox'
MailParser = require("mailparser").MailParser

class EmailListener extends EventEmitter
  constructor: () ->
  
  init: (fetchExisting = true)->
    imapSettings = config.get('email.imap')

    @client = inbox.createConnection(
      imapSettings.port, 
      imapSettings.host, {
        secureConnection: true
        auth: {
          user: imapSettings.user
          pass: imapSettings.pass
        }
      }
    )

    defered = Q.defer();

    log.info "Connecting to email server..."

    @client.on 'error', (e)->
      e.it_source = "Email server (IMAP)"
      e.message = "IT: #{e.message}"
      return defered.reject(e)

    @client.on 'connect', (e)=>
      if e?
        log.error "Could not connect to email server. #{e}"
        e.it_source = "Email server (IMAP)"
        e.message = "IT: #{e.message}"
        return defered.reject(e) 

      log.info "Connected to email server [IMAP]..."


      @client.openMailbox 'INBOX', (error, info) =>
        return defered.reject(e) if e?
        defered.resolve()

        if fetchExisting
          query = {unseen: true, not: {seen: true}}
          
          # fetch unread new emails
          @client.search(query, true, (e,messages)=>
            return log.error(e) if e?
            log.info "#{messages.length} new emails found on inbox..."
            messages.forEach (message)=>
              mailparser = new MailParser()
              @client.createMessageStream(message).pipe(mailparser)

              mailparser.on("end",(obj)=>
                @checkAndEmit(message, obj)
              );
          )

        # Listen to new ones
        @client.on 'new', (message)=>
          log.info "New inbound email ..."

        
          mailparser = new MailParser()
          @client.createMessageStream(message.UID).pipe(mailparser)

          mailparser.on("end",(obj)=>
            @checkAndEmit(message.UID, obj)
          );

    @client.connect();
    return defered.promise;
    
  reconnect: ()->

    log.info "Reconnecting to Email server (IMAP)"
    if @disConnectInProgress
      @init();
      @disConnectInProgress = false;
      return;
    
    @client.close();
    @disConnectInProgress = true;
    @client.on('close', =>
      @disConnectInProgress = false;
      log.info "Disconnected from Email server (IMAP)"
      @init();
    );

  checkAndEmit: (uid, obj)->
    formatedObj = {
      from        : obj.from[0].address
      to          : obj.to[0].address
      body        : obj.text
      subject     : obj.subject
      attachments : obj.attachments
      timestamp   : obj.receivedDate.valueOf()
      uid         : uid
    }
    @emit("new-email", formatedObj)

  markAsProcessed: (message, cb)->
    @client.addFlags message.uid,['\\\\Seen'], cb


module.exports = EmailListener
