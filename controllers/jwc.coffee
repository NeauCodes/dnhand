_ = require 'lodash'
Then = require 'thenjs'
express = require 'express'
debug = require('debug')('dnhand:ctrl:jwc')

log = require 'winston'
OpenIdService = require '../services/OpenId'
StudentService = require '../services/Student'
GradeService = require '../services/Grade'
{comMsg} = require '../middleware/wechat'

{oauthApi} = require '../lib/wechatApi'
module.exports = router = express.Router()

router.get '/test', (req, res) ->
  res.end "#{req.protocol}://#{req.hostname}/hello"

router.get '/bind', (req, res) ->
  if req.query.dev is 'yes'
    openid = req.query.openid
    req.session.openid = openid
    res.render 'jwc/bind'
    return

  code = req.query.code
  unless code
    oauthUrl = oauthApi
      .getAuthorizeURL "#{req.protocol}://#{req.hostname}/jwc/bind"
    res.redirect oauthUrl
    return

  oauthApi.getAccessToken code, (err, result) ->
    unless result.data
      return res.end '发生错误请稍候再试'
    openid = result.data.openid
    debug "bind openid: #{openid}"
    req.session.openid = openid
    res.render 'jwc/bind'

router.post '/bind', (req, res) ->
  stuid  = req.body.stuid
  pswd   = req.body.pswd
  openid = req.session.openid

  unless stuid and pswd and openid
    log.debug 'wrong parameter from bind'
    return res.json errcode: -1

  debug "bind #{stuid} -> #{openid}"

  student = new StudentService stuid, pswd

  Then (cont) ->
    student.login cont

  .then (cont, result) ->
    OpenIdService.bindStuid openid, stuid, cont

  .then (cont, openid) ->
    student.getInfoAndSave cont

  .then (cont) ->
    res.json errcode: 0
    process.nextTick ->
      comMsg.sendBindSuccessMsg(openid, stuid)

  .fail (cont, err) ->
    if err.name isnt 'loginerror'
      log.error err

    if err.errcode
      res.json err
    else
      res.json {errcode: -1, errmsg: 'other'}
