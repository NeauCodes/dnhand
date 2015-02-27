mongoose = require 'mongoose'

OpenIdSchema = new mongoose.Schema
  openid: String
  youzanId: Number
  stuid: String
  nickname: String
  sex: String
  city: String
  province: String
  headimgurl: String

module.exports = OpenIdSchema
