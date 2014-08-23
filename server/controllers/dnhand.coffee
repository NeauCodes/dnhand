wechat  = require "wechat"
request = require "request"
Student = require '../models/Student'
OpenId  = require '../models/OpenId'
iconv = require 'iconv-lite'
cheerio = require 'cheerio'
_ = require 'underscore'

info = require './info'

class ImageText
  constructor: (title, description, url, picurl) ->
    @title = title
    @description = description
    @url = url
    @picurl = picurl


handler = (req, res) ->
  msg = req.weixin
  ct = msg.Content ? msg.EventKey
  if msg.Event is "subscribe" or !ct
    replyNoMatchMsg req, res

  else if req.wxsession.status
    zt = req.wxsession.status
    if ct is "取消"
      delete req.wxsession.status
      return res.reply "已返回正常模式"

  else if ct is "allgrade"
    info.getProfileByOpenid msg.FromUserName, (err, student) ->
      if err
        if err.message is 'openid not found'
          return res.reply "查询成绩需先绑定账户\n   请回复'绑定'"
        else
          return res.reply "请稍候再试"

      desc = """
            #{student.name}同学

            请点击查看你的成绩单
            """
      url = "http://n.feit.me/info/allgrade/#{msg.FromUserName}"
      imageTextItem = new ImageText("#{student.name}同学的全部成绩", desc)
      return res.reply([imageTextItem])

  else if ct is "nowgrade"
    getNowGrade(req, res)

  else if ct is "bjggrade"
    getBjgGrade(req, res)

  else if ct is "hi"
    title = "东农助手"
    desc = """
          Hi 你好
          我的名字叫 费腾
          很高兴和你成为朋友
          安卓手机直接点这条信息就能添加我
          苹果手机或者没反应可以加我微信号
          微信号：q13027722
          """
    url = "weixin://contacts/profile/q13027722"
    imageTextItem = new ImageText(title, desc, url)
    return res.reply([imageTextItem])

  else if ct is "youni"
    title = "东农助手"
    desc = """
          有问题可以加我微信，回复'hi'，查看我的微信号
          """
    url = "weixin://contacts/profile/q13027722"
    imageTextItem = new ImageText(title, desc, url)
    return res.reply([imageTextItem])

  else if ct.substring(0, 1) is "A" and ct.length is 9
    info.getProfileByStuid ct, (err, student) ->
      return res.reply "请稍候再试" if err
      req.wxsession.stuid = ct
      if student
        title = "东农助手"
        desc = """
              Hi
              #{student.major}专业
              #{student.class} 的 #{student.name}同学
              """
        imageTextItem = new ImageText(title, desc)
        return res.reply([imageTextItem])
      else
        return res.reply "未找到相关信息"

  else if ct.substring(0, 2) is "补考"
    stuid = ct.substring(2)
    if stuid.substring(0, 1) is "A" and stuid.length is 9
      info.getExamInfo stuid, (err, msgs) ->
        if err
          return res.reply '请稍候再试'
        _replyExamInfo(msgs, res)
    else 
      return res.reply '学号格式不正确'

  else if ct is "exam"
    return res.reply "请回复 '补考'+'学号' 查询补考信息\n例如查询学号为A19120000的补考信息\n'补考A19120000'"

  else if ct is '绑定'
    title = "东农助手"
    desc = """
          请点击本消息绑定学号
          """
    url = "http://n.feit.me/bind/#{msg.FromUserName}"
    imageTextItem = new ImageText(title, desc, url)
    return res.reply([imageTextItem])
  else
    replyNoMatchMsg req, res

replyNoMatchMsg = (req, res) ->
  info.isBind req.weixin.FromUserName, (err, openid) ->
    if err
      return res.reply '请稍候再试'
    if openid
      info.getProfileByStuid openid.stuid, (err, student) ->
        title = "东农助手"
        desc = """
              #{student.name || ""}同学
              感谢你的支持~
              """
        imageTextItem = new ImageText(title, desc)
        return res.reply([imageTextItem])
    else
      title = "东农助手"
      desc = """
            请点击本消息绑定学号
            """
      url = "http://n.feit.me/bind/#{msg.FromUserName}"
      imageTextItem = new ImageText(title, desc, url)
      return res.reply([imageTextItem])

getTodaySyllabus = (req, res) ->
  msg = req.weixin
  info.getProfileByOpenid msg.FromUserName, (err, student) ->

getNowGrade = (req, res) ->
  msg = req.weixin
  info.getProfileByOpenid msg.FromUserName, (err, student) ->
    if err
      if err.message is 'openid not found'
        return res.reply "查询成绩需先绑定账户\n   请回复'绑定'"
      else
        return res.reply "请稍候再试"
    if student && student.pswd && student.is_pswd_invalid != true
      info.getQbGrade student.stuid, (err, grade) ->
        if !grade
          info.updateUserData(student.stuid)
          return res.reply('正在获取你的信息\n     请稍候...')
        result = grade['qb']['2013-2014学年春(两学期)']
        if !result || result.length is 0
          return res.reply('暂时还没有上学期成绩信息')
        gradeStr = ["姓名：#{student.name}\n"]
        gradeStr.push("学号；#{student.stuid}\n")
        for item in result
          gradeStr.push("#{item.kcm}\n")
          gradeStr.push("成绩：#{item.cj}\n")
        gradeStr.push("仅显示及格科目成绩！")
        res.reply(gradeStr.join(''))
        info.updateUserData(student.stuid)
    else
      res.reply """
                你未绑定学号或更改了教务系统密码
                请回复'绑定'重新认证身份信息
                """

getBjgGrade = (req, res) ->
  msg = req.weixin
  info.getProfileByOpenid msg.FromUserName, (err, student) ->
    if err
      if err.message is 'openid not found'
        return res.reply "查询成绩需先绑定账户\n   请回复'绑定'"
      else
        return res.reply "请稍候再试"
    if student && student.pswd && student.is_pswd_invalid != true
      info.getAllGrade student.stuid, (err, grade) ->
        if !grade
          info.updateUserData(student.stuid)
          return res.reply('正在获取你的信息\n     请稍候...')
        result = _.values(grade['fa'])[0]
        if !result || result.length is 0
          return res.reply('没找到不及格成绩信息')
        gradeStr = ["姓名：#{student.name}\n"]
        gradeStr.push("学号；#{student.stuid}\n")
        for item in result
          if Number(item.cj) < 60 || item.cj is "不及格"
            gradeStr.push("#{item.kcm}\n")
            gradeStr.push("学分：#{item.xf}\n")
            gradeStr.push("成绩：#{item.cj}\n")
        res.reply(gradeStr.join(''))
        info.updateUserData(student.stuid)
    else
      res.reply """
                你未绑定学号或更改了教务系统密码
                请回复'绑定'重新认证身份信息
                """

_replyExamInfo = (msgs, res) ->
  if msgs.length is 0
    return res.reply '暂无考试信息'
  else
    examInfo = []
    examInfo.push('姓名:' + msgs[0].stuName + '\n')
    examInfo.push('学号:' + msgs[0].stuid + '\n')
    examInfo.push('------------------\n')
    for msg in msgs
      examInfo.push("科目名:#{msg.courseName}\n")
      examInfo.push("时间:#{msg.time}\n")
      examInfo.push("地点:#{msg.location}\n")
      examInfo.push("------------------\n")
    return res.reply examInfo.join('')

module.exports = wechat "feit", handler