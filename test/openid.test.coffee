Then = require 'thenjs'
should = require 'should'
config = require '../config'

openIdService = require '../services/OpenId'
openid = config.wechat.testOpenid

describe 'OpenIdService', () ->
  describe 'getUser', () ->
    it 'get user info without db should ok', (done) ->
      openIdService.removeUser openid, (err, removedUser) ->
        openIdService.getUser openid, (err, user) ->
          should.not.exist err
          user.should.have.property '_id'
          user.should.have.property 'openid'
          user.city.should.equal '哈尔滨'
          user.sex.should.equal '1'
          done()

    it 'get user info from db should ok', (done) ->
      openIdService.getUser openid, (err, user) ->
        should.not.exist err
        user.should.have.property '_id'
        user.should.have.property 'openid'
        user.city.should.equal '哈尔滨'
        user.sex.should.equal '1'
        done()

  describe 'bindStuid', () ->
    it 'bind student id should ok', (done) ->
      openIdService.bindStuid openid, 'A19120626', (err, user) ->
        should.not.exist err
        user.openid.should.equal openid
        user.stuid.should.equal 'A19120626'
        done()

  describe 'unBindStuid', () ->
    it 'unbind student id should ok', (done) ->
      openIdService.unBindStuid openid, (err, user) ->
        should.not.exist err
        user.openid.should.equal openid
        user.stuid.should.equal ''
        done()
