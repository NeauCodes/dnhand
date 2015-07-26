express    = require 'express'
bodyParser = require 'body-parser'
session    = require 'express-session'
log        = require 'winston'
require './models'

config     = require './config'

wechat       = require 'wechat'
wechatHanler = require './middleware/wechat'
jwcRouter = require './controllers/jwc'
youzanRouter = require './controllers/youzan'
tokenRouter = require './controllers/token'
oauthRouter = require './controllers/wechat-oauth'

app = express()

app.set 'trust proxy', true
app.use session({
  secret: config.session.secret
  resave: false
  saveUninitialized: true
})

# wechat
app.use '/wx/api', wechat(config.wechat.token, wechatHanler)

# body parse
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

# static files
staticDir = require('path').join(__dirname, 'public')
app.use '/public', express.static(staticDir)

# client res
clientDir = require('path').join __dirname, 'client'
app.use express.static clientDir

# view engin
app.set 'views', './views'
app.set('view engine', 'html')
app.engine('html', require('ejs').renderFile)

app.use oauthRouter
app.use '/jwc', jwcRouter
app.use '/token', tokenRouter
app.use '/youzan', youzanRouter

app.listen config.port, () ->
  log.info "Server Start at port #{config.port}"
