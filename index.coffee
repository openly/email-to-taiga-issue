require './globals'

EmailListener = require './lib/email-listener'
TaigaConn = require './lib/taiga-conn'
SlackMessenger = require './lib/slack-messenger'

taigaConn = new TaigaConn
emailListener = new EmailListener

emailListener.init()


emailListener.on('new-email',(mail)->
  user = null;
  
  log.info "Creating issue for email \"#{mail.subject}\"..."

  taigaConn.login().then((theUser)->
    user = theUser

    log.info "Authenticated with Taiga."

    return taigaConn.getProject(user.auth_token, config.get('taiga.project'))
  ).then((project)->
    log.info "Got project details."

    return taigaConn.createIssue(user.auth_token, {
      subject: mail.subject,
      project: project.id
      description: """
      Sent by: #{mail.from}

      #{mail.body}
      """
    })
  ).then((issue)->
    log.info "Created issue."

    emailListener.markAsProcessed mail,->

    SlackMessenger.notify "Created <https://tree.taiga.io/project/#{config.get('taiga.project')}/issue/#{issue.ref}|issue in taiga> form email \"#{mail.subject}\"..."
  ).fail((e)->
    log.error e
  )
)